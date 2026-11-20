# VideoTurko kur.ps1: kontrol0 -> motor -> model -> KONTROL -> HAZIR.  EN: setup script, prints HAZIR/READY only after a real tiny generation works.
# Kullanim / usage (PowerShell, repo klasorunde):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1 -Adim kontrol0        (yalniz donanim kontrolu)
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1 -Kuru                (hicbir sey indirmez/kurmaz, rapor)
#   -ModelKlasoru <yol>  (var olan model klasoru: sha256 eslesen dosya hardlink/kopya ile baglanir, indirilmez; eslesmeyen normal indirilir)
#   -Adim kontrol0,motor,model,kontrol   (varsayilan: hepsi)   -LisansKabul E|Y   -MotorZip <yerel zip>  -CudaZip <yerel zip>  -Zorla
# Her adim tekrar calistirilabilir: dogru sha256'li dosya atlanir. Durdurma: <VT_ROOT>\DUR dosyasi -> DURDU, .part korunur.
# Ortam / env: VT_ROOT, VT_ENGINE_BIN, VT_MODEL_DIR (bkz. uret.ps1). Kisisel yol yoktur.
# Cikis kodlari / exit: 0 HAZIR (ya da -Kuru raporu tamam), 1 hata, 2 lisans kabul gerekli, 3 donanim/disk yetersiz, 4 DURDU.
param(
    [string[]]$Adim = @('kontrol0', 'motor', 'model', 'kontrol'),
    [switch]$Kuru,
    [string]$LisansKabul = '',
    [string]$MotorZip = '',
    [string]$CudaZip = '',
    [string]$ModelKlasoru = '',
    [switch]$Zorla
)
$ErrorActionPreference = 'Stop'
$Adim = @($Adim | ForEach-Object { $_ -split ',' } | ForEach-Object { $_.Trim() } | Where-Object { $_ })
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Root = $(if ($env:VT_ROOT) { $env:VT_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..')).Path })
$Motor = $(if ($env:VT_ENGINE_BIN) { $env:VT_ENGINE_BIN } else { Join-Path $Root 'engine\bin' })
$ModelDir = $(if ($env:VT_MODEL_DIR) { $env:VT_MODEL_DIR } else { Join-Path $Root 'model' })
$DurDosya = Join-Path $Root 'DUR'
$MinBosGiB = 32; $PayGiB = 15

# --- Zip adlari paketleme betigiyle ayni (motor adindaki surum numarasi yayin surumudur; VT_MOTOR_ZIP_AD ile ezilir).
# --- Release adresleri: release henuz yayinlanmadi; adres ve sha256 YER TUTUCUDUR (yayin sonrasi doldurulur).
# --- Release URLs/sha256 are PLACEHOLDERS until the release exists; override with VT_MOTOR_URL / VT_MOTOR_SHA256 / VT_CUDA_URL / VT_CUDA_SHA256.
$ZipMotor = @{ ad = $(if ($env:VT_MOTOR_ZIP_AD) { $env:VT_MOTOR_ZIP_AD } else { 'videoturko-motor-0.1.0-win64-cuda12.8-sm61.zip' }); url = $(if ($env:VT_MOTOR_URL) { $env:VT_MOTOR_URL } else { 'https://github.com/alexturkey/VideoTurko/releases/download/v0.1.0/videoturko-motor-0.1.0-win64-cuda12.8-sm61.zip' }); sha = $(if ($env:VT_MOTOR_SHA256) { $env:VT_MOTOR_SHA256 } else { '7d28ff900ef4799f75cbe91c39e0a7b260f0207a7e2a4ebd3d8450590b79a64d' }) }
$ZipCuda = @{ ad = 'videoturko-cuda-runtime-12.8-win64.zip'; url = $(if ($env:VT_CUDA_URL) { $env:VT_CUDA_URL } else { 'https://github.com/alexturkey/VideoTurko/releases/download/v0.1.0/videoturko-cuda-runtime-12.8-win64.zip' }); sha = $(if ($env:VT_CUDA_SHA256) { $env:VT_CUDA_SHA256 } else { '344a0b04f043fb9cccdfe38ec77716afb59bafb894f11f0fac2365f151777355' }) }

function Say([string]$m) { Write-Output $m }
function Dur-Kontrol { if (Test-Path -LiteralPath $DurDosya) { Say 'DURDU (DUR dosyasi)'; exit 4 } }
function Sha256([string]$p) { (Get-FileHash -Algorithm SHA256 -LiteralPath $p).Hash.ToLower() }
$uyari = New-Object System.Collections.ArrayList
$modelAdlari = @('minimax_h3_fl2va_hyperflow_flash_14b-Q4_K_M.gguf', 'qwen3vl_32b_minimax_h3-Q4_K_M.gguf', 'minimax_h3_sol_vae_fp16.safetensors', 'minimax_h3_audio_vae_fp32.safetensors')

# ---------------------------------------------------------------- kontrol0
function Adim-Kontrol0 {
    Say '== kontrol0: donanim ve ortam (hicbir sey indirilmez)'
    $os = [Environment]::OSVersion.Version
    Say ("  Windows {0}.{1} build {2}" -f $os.Major, $os.Minor, $os.Build)
    if ($os.Major -lt 10) { Say '  HATA: Windows 10 ya da ustu gerekir'; exit 3 }
    # GPU
    $smi = Get-Command nvidia-smi.exe -ErrorAction SilentlyContinue
    if (-not $smi) { Say '  HATA: nvidia-smi yok: NVIDIA sofor/surucu kurulu degil ya da NVIDIA kart yok (bu motor yalniz NVIDIA CUDA).'; exit 3 }
    $q = (& nvidia-smi.exe --query-gpu=name,memory.total,driver_version,compute_cap --format=csv,noheader,nounits 2>$null | Select-Object -First 1)
    if (-not $q) { Say '  HATA: nvidia-smi cikti vermedi'; exit 3 }
    $f = $q -split ',' | ForEach-Object { $_.Trim() }
    $gpuAd = $f[0]; $vram = [double]$f[1]; $surucu = $f[2]; $cc = $(if ($f.Count -ge 4) { $f[3] } else { '' })
    Say ("  GPU: {0}, {1:N0} MiB, surucu {2}, compute capability {3}" -f $gpuAd, $vram, $surucu, $cc)
    if ($vram -lt 3800) { Say '  HATA: en az 4 GB VRAM gerekir'; if (-not $Zorla) { exit 3 } }
    $ccOk = $false; $ccV = 0.0
    if ([double]::TryParse(($cc -replace ',', '.'), [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$ccV)) { $ccOk = $true }
    if ($ccOk -and $ccV -lt 6.1) { Say '  HATA: compute capability 6.1 (Pascal) ya da ustu gerekir'; if (-not $Zorla) { exit 3 } }
    if ($gpuAd -notmatch '1050 Ti') { [void]$uyari.Add("Dogrulanmis donanim yalniz GTX 1050 Ti 4 GB (sm_61). $gpuAd denenmedi; devam edebilirsiniz ama sonuc garanti degil.") }
    # --- Monster/Ampere devri: bu depodaki yayin motoru Pascal sm_61 icindir. Pascal'dan yeni bir kart
    # --- gorulurse (RTX 20xx/30xx/40xx...) sm_86 motorunu kuran scripts\kur-monster.ps1'e devret.
    # --- Sarmalayici VT_MOTOR_URL set ettigi icin geri donus (sonsuz dongu) olmaz.
    if ($ccOk -and $ccV -gt 6.1 -and -not $env:VT_MOTOR_URL) {
        $sm = Join-Path $PSScriptRoot 'kur-monster.ps1'
        if (Test-Path -LiteralPath $sm) {
            Say ("  compute capability {0}: Pascal (sm_61) degil -> sm_86 motorunu kuran kur-monster.ps1 devraliyor" -f $ccV)
            $devir = @('-Adim', ($Adim -join ','))
            if ($Kuru) { $devir += '-Kuru' }
            if ($Zorla) { $devir += '-Zorla' }
            if ($LisansKabul) { $devir += @('-LisansKabul', $LisansKabul) }
            if ($ModelKlasoru) { $devir += @('-ModelKlasoru', $ModelKlasoru) }
            if ($MotorZip) { $devir += @('-MotorZip', $MotorZip) }
            if ($CudaZip) { $devir += @('-CudaZip', $CudaZip) }
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $sm @devir
            exit $LASTEXITCODE
        }
        Say '  UYARI: bu kart sm_61 degil; yayin motoru sm_61 icindir. RTX 2050 icin scripts\kur-monster.ps1 kullanin.'
    }
    # RAM
    $os2 = Get-CimInstance Win32_OperatingSystem
    $ramGB = [Math]::Round($os2.TotalVisibleMemorySize / 1MB, 1); $bosGB = [Math]::Round($os2.FreePhysicalMemory / 1MB, 1)
    Say ("  RAM: toplam {0} GB, bos {1} GB" -f $ramGB, $bosGB)
    if ($ramGB -lt 12) { Say '  HATA: en az 16 GB RAM onerilir (olculen RAM tepe ~11,5 GB); 12 GB alti desteklenmez'; if (-not $Zorla) { exit 3 } }
    elseif ($ramGB -lt 15.5) { [void]$uyari.Add("RAM $ramGB GB: 16 GB onerilir; kosu sirasinda diger uygulamalari kapatin, takas (sayfa dosyasi) yavaslatabilir.") }
    # Disk
    $hepsiVar = $true; foreach ($n in $modelAdlari) { if (-not (Test-Path -LiteralPath (Join-Path $ModelDir $n))) { $hepsiVar = $false } }
    $surucuHarf = (Split-Path -Qualifier ([IO.Path]::GetFullPath($ModelDir))).TrimEnd(':')
    $drv = Get-PSDrive -Name $surucuHarf -ErrorAction SilentlyContinue
    if ($drv) {
        $bosGiB = [Math]::Round($drv.Free / 1GB, 1)
        Say ("  Disk {0}: bos {1} GiB (model klasoru {2})" -f $surucuHarf, $bosGiB, $ModelDir)
        if (-not $hepsiVar -and $bosGiB -lt ($MinBosGiB + $PayGiB)) { Say ("  HATA: model indirmek icin en az {0} GiB bos gerekir ({1} model + {2} pay)" -f ($MinBosGiB + $PayGiB), $MinBosGiB, $PayGiB); if (-not $Zorla) { exit 3 } }
        try {
            $pd = Get-Partition -DriveLetter $surucuHarf -ErrorAction Stop | Get-Disk | Get-PhysicalDisk
            Say ("  Disk turu: {0}" -f $pd.MediaType)
            if ($pd.MediaType -eq 'HDD') { [void]$uyari.Add('Model klasoru HDD uzerinde: ilk adimlar 15-25 kat yavas olur (olculdu). NVMe/SSD onerilir (VT_MODEL_DIR).') }
        } catch { Say '  Disk turu okunamadi (atlandi)' }
    }
    # VC++
    $vcDll = Join-Path $env:SystemRoot 'System32\vcruntime140.dll'; $mpDll = Join-Path $env:SystemRoot 'System32\msvcp140.dll'
    if ((Test-Path -LiteralPath $vcDll) -and (Test-Path -LiteralPath $mpDll)) { Say ("  VC++ calisma zamani: var (vcruntime140 {0})" -f (Get-Item -LiteralPath $vcDll).VersionInfo.ProductVersion) }
    else { [void]$uyari.Add('Visual C++ 2015-2022 x64 Redistributable bulunamadi (System32\vcruntime140.dll/msvcp140.dll yok): Microsoft sayfasindan kurun (sd-cli acilmazsa nedeni budur).') }
    foreach ($u in $uyari) { Say "  UYARI: $u" }
    Say '== kontrol0 tamam'
}

# ---------------------------------------------------------------- motor
function Zip-Al($z, [string]$yerel, [string]$hedefDizin) {
    New-Item -ItemType Directory -Force $hedefDizin | Out-Null
    $zipYol = $(if ($yerel) { $yerel } else { Join-Path $hedefDizin $z.ad })
    if (-not $yerel) {
        if ($z.url -like '__*' -or $z.sha -like '__*') { throw "ZIP2:release adresi/sha256 henuz yok ($($z.ad)): release yayinlanana kadar motor zip dosyasi gerekir" }
        if (-not ((Test-Path -LiteralPath $zipYol) -and ((Sha256 $zipYol) -eq $z.sha.ToLower()))) {
            $part = "$zipYol.part"
            Write-Host "  indiriliyor: $($z.ad)"
            & curl.exe -L --fail --retry 3 --retry-delay 5 -C - --progress-bar -o $part $z.url
            if ($LASTEXITCODE -ne 0) { throw "indirme basarisiz: $($z.url)" }
            $got = Sha256 $part
            if ($got -ne $z.sha.ToLower()) { Remove-Item -LiteralPath $part -Force; throw "sha256 tutmadi: $($z.ad) beklenen $($z.sha) gelen $got" }
            Move-Item -LiteralPath $part -Destination $zipYol -Force
        }
    } else {
        if (-not (Test-Path -LiteralPath $zipYol)) { throw "ZIP2:yerel zip dosyasi bulunamadi: $zipYol" }
        # Oncelik: GOMULU sha (yayin sonrasi dolu) -> yanindaki .sha256 YOK SAYILIR (ezilme yok). Yer tutucuysa yan .sha256 yedek ve BAGIMSIZ DEGIL.
        $beklenen = ''; $kaynakSha = ''
        if (-not ($z.sha -like '__*')) { $beklenen = $z.sha.ToLower(); $kaynakSha = 'gomulu' }
        elseif (Test-Path -LiteralPath "$zipYol.sha256") { $beklenen = ((Get-Content -LiteralPath "$zipYol.sha256" -TotalCount 1) -split '\s+')[0].ToLower(); $kaynakSha = 'yan .sha256' }
        if ($beklenen) {
            if ((Sha256 $zipYol) -ne $beklenen) { throw "yerel zip sha256 tutmadi ($kaynakSha): $zipYol" }
            if ($kaynakSha -eq 'yan .sha256') { Write-Host "  UYARI: yan .sha256 ile dogrulandi (self-referential, not independent: yalniz bozulmayi yakalar, kasitli degistirmeyi yakalamaz; release sha256'si henuz yok): $zipYol" }
        }
        else { Write-Host "  UYARI: sha256 dogrulanmadi (release sha256'si henuz yok ve $zipYol.sha256 dosyasi yanina konmamis): $zipYol" }
    }
    return $zipYol
}
function Adim-Motor {
    Say '== motor: sd-cli ikili + CUDA calisma zamani DLL (sha256 dogrulamali)'
    $sd = Join-Path $Motor 'sd-cli.exe'
    $dll = @('cudart64_12.dll', 'cublas64_12.dll', 'cublasLt64_12.dll')
    $var = (Test-Path -LiteralPath $sd) -and (-not ($dll | Where-Object { -not (Test-Path -LiteralPath (Join-Path $Motor $_)) }))
    if ($var -and -not $MotorZip -and -not $CudaZip) { Say '  motor zaten var (atlandi)' }
    else {
        if ($Kuru) { Say "  KURU: motor ve cuda zip indirilecekti -> $($Motor)"; return }
        $tmp = Join-Path $Root 'indirme'
        try {
        foreach ($p in @(@($ZipMotor, $MotorZip), @($ZipCuda, $CudaZip))) {
            Dur-Kontrol
            $zip = Zip-Al $p[0] $p[1] $tmp
            $ac = Join-Path $tmp ('ac_' + $p[0].ad)
            if (Test-Path -LiteralPath $ac) { Remove-Item -LiteralPath $ac -Recurse -Force }
            Expand-Archive -LiteralPath $zip -DestinationPath $ac -Force
            New-Item -ItemType Directory -Force $Motor | Out-Null
            # Iki zip'te ayni adli README.txt / SHA256SUMS.txt var (icerikleri farkli): ikili ve DLL'ler $Motor'a, geri kalan (lisans, README, SHA256SUMS) zip adli alt klasore: cakisma yok.
            $dosyalar = @(Get-ChildItem -LiteralPath $ac -Recurse -File)
            $sumsL = @($dosyalar | Where-Object { $_.Name -like 'SHA256SUMS*.txt' })   # SHA256SUMS.txt ya da SHA256SUMS-motor/-cuda.txt
            foreach ($sumsF in $sumsL) {
                foreach ($satir in Get-Content -LiteralPath $sumsF.FullName) {
                    if ($satir -match '^([0-9a-fA-F]{64})\s+\*?(.+)$') {
                        $f = $dosyalar | Where-Object { $_.Name -eq $Matches[2].Trim() } | Select-Object -First 1
                        if (-not $f) { throw "zip icinde SHA256SUMS.txt'de listeli dosya yok: $($Matches[2])" }
                        if ((Sha256 $f.FullName) -ne $Matches[1].ToLower()) { throw "zip icindeki dosya sha256 tutmadi: $($f.Name)" }
                    }
                }
            }
            $lis = Join-Path (Join-Path (Split-Path -Parent $Motor) 'lisanslar') ([IO.Path]::GetFileNameWithoutExtension($zip)); New-Item -ItemType Directory -Force $lis | Out-Null
            foreach ($f in $dosyalar) {
                if ($f.Extension -in @('.exe', '.dll')) { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $Motor $f.Name) -Force }
                else { Copy-Item -LiteralPath $f.FullName -Destination (Join-Path $lis $f.Name) -Force }
            }
            Remove-Item -LiteralPath $ac -Recurse -Force
            Say "  yerlestirildi: $($p[0].ad)"
        }
        } catch {
            $mesaj = $_.Exception.Message; $kod = 1
            if ($mesaj.StartsWith('ZIP2:')) { $mesaj = $mesaj.Substring(5); $kod = 2 }
            Say "MOTOR ADIMI DURDU: $mesaj"
            Say '  Yerel zip icin: -MotorZip <yol> -CudaZip <yol> verin (docs\KURULUM.md). Model indirilmedi/motor kurulmadi.'
            exit $kod
        }
    }
    # DLL yukleme yoklamasi (eksik DLL = 0xC0000135)
    if (-not (Test-Path -LiteralPath $sd)) { throw "sd-cli.exe yok: $Motor" }
    $eskiPath = $env:PATH; $env:PATH = "$Motor;$env:PATH"
    try { $sp = Start-Process -FilePath $sd -ArgumentList '--help' -WindowStyle Hidden -PassThru -Wait -RedirectStandardOutput (Join-Path $Root 'runs\yoklama_out.txt') -RedirectStandardError (Join-Path $Root 'runs\yoklama_err.txt') } catch { throw "sd-cli baslatilamadi: $($_.Exception.Message)" } finally { $env:PATH = $eskiPath }
    if ($sp.ExitCode -eq -1073741515) { throw 'sd-cli DLL eksik (0xC0000135): cudart/cublas ve VC++ calisma zamanini kontrol edin' }
    Say "  sd-cli yoklamasi tamam (cikis $($sp.ExitCode))"
}

# ---------------------------------------------------------------- model
function Model-Bagla {
    $kayit = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'modeller.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    New-Item -ItemType Directory -Force $ModelDir | Out-Null
    foreach ($d in $kayit.dosyalar) {
        Dur-Kontrol
        $k = Join-Path $ModelKlasoru $d.hedef; $h = Join-Path $ModelDir $d.hedef
        if (-not (Test-Path -LiteralPath $k)) { Say "  baglanmadi (kaynakta yok): $($d.hedef)"; continue }
        if ((Test-Path -LiteralPath $h) -and ((Get-Item -LiteralPath $h).Length -eq $d.boyut)) { Say "  zaten var: $($d.hedef)"; continue }
        Say "  sha256 hesaplaniyor: $($d.hedef) (buyuk dosya, dakikalar surer)"
        if ((Sha256 $k) -ne $d.sha256.ToLower()) { Say "  UYARI: sha256 eslesmedi, baglanmadi (indirilecek): $($d.hedef)"; continue }
        if ([IO.Path]::GetPathRoot($k) -eq [IO.Path]::GetPathRoot($h)) { & cmd.exe /c mklink /H "$h" "$k" 2>&1 | Out-Null }
        if (-not (Test-Path -LiteralPath $h)) { Copy-Item -LiteralPath $k -Destination $h }
        Say "  BAGLANDI (yerel dosyadan, indirilmedi): $($d.hedef)"
    }
}
function Adim-Model {
    Say '== model: 4 model dosyasi (commit-sabit adres + sha256), lisans kabul gerekir'
    $ind = Join-Path $PSScriptRoot 'modelleri_indir.ps1'
    if (-not (Test-Path -LiteralPath $ind)) { throw "modelleri_indir.ps1 yok: $ind" }
    $lisans = Join-Path $PSScriptRoot '..\docs\LISANS_KABUL.txt'
    if ($Kuru) { & powershell.exe -NoProfile -File $ind -Kuru -Hedef $ModelDir; return }
    if ($ModelKlasoru) { Model-Bagla }
    $kabul = $LisansKabul
    if (-not $kabul) {
        Get-Content -LiteralPath $lisans | ForEach-Object { Say $_ }
        try { $kabul = Read-Host 'Onay / Confirm (TR: E  |  EN: Y)' }
        catch { Say 'Lisans kabulu etkilesimsiz alinamadi: kullaniciya sorun, kabul gelince -LisansKabul E (ya da Y) ile calistirin; model indirilmedi.'; exit 2 }
        if ($null -eq $kabul) { $kabul = '' }
    }
    if ($kabul.Trim().ToUpper() -notin @('E', 'Y')) { Say 'Lisans kabul edilmedi: model indirilmeyecek.'; exit 2 }
    Dur-Kontrol
    & powershell.exe -NoProfile -File $ind -Baslat -LisansKabul $kabul.Trim().ToUpper() -Hedef $ModelDir
    $k = $LASTEXITCODE
    if ($k -eq 4) { Say 'DURDU (indirici)'; exit 4 }
    if ($k -eq 3) { Say 'Disk yetersiz'; exit 3 }
    if ($k -eq 2) { Say 'Lisans kabul gerekli'; exit 2 }
    if ($k -ne 0) { throw "modelleri_indir.ps1 cikis $k" }
    Say '  modeller tamam'
}

# ---------------------------------------------------------------- kontrol (gercek cekirdek)
function Adim-Kontrol {
    Say '== kontrol: 5 karelik GERCEK uretim (uret.ps1 ile ayni cagri yolu); yalniz basariliysa HAZIR'
    if ($Kuru) { Say '  KURU: kontrol uretimi calistirilmadi'; return }
    $kd = Join-Path $Root 'runs\kontrol'; New-Item -ItemType Directory -Force $kd | Out-Null
    $istem = Join-Path $kd 'istem.txt'
    Set-Content -LiteralPath $istem -Value 'A calm lake at sunrise with gentle ripples and soft mist, cinematic, photorealistic, quiet ambient sound.' -Encoding ASCII
    $cikti = Join-Path $kd 'kontrol.avi'
    if (Test-Path -LiteralPath $cikti) { Remove-Item -LiteralPath $cikti -Force }
    $t0 = Get-Date
    & powershell.exe -NoProfile -File (Join-Path $PSScriptRoot 'uret.ps1') -Istem $istem -Kare 5 -Cikti $cikti -Kontrol -TavanDk 30
    $k = $LASTEXITCODE
    $sn = [int]((Get-Date) - $t0).TotalSeconds
    if ($k -eq 2) { Say 'DURDU'; exit 4 }
    if ($k -ne 0 -or -not (Test-Path -LiteralPath $cikti)) {
        Say "KONTROL BASARISIZ (cikis $k, $sn sn): HAZIR YAZILMAZ. Bakin: $kd\ham_err_kontrol_a1.txt"
        Say 'Sik nedenler: eksik DLL/VC++, surucu eski, model eksik/bozuk (-Adim model), VRAM/RAM yetersiz (diger uygulamalari kapatin).'
        exit 1
    }
    $kayit = [ordered]@{ hazir = $true; tarih = (Get-Date).ToString('s'); kontrol_sn = $sn; kontrol_kare = 5 }
    ($kayit | ConvertTo-Json) | Set-Content -LiteralPath (Join-Path $Root 'runs\hazir.json') -Encoding ASCII
    Say ("HAZIR / READY (kontrol uretimi {0} sn). Video icin: powershell -File scripts\uret.ps1 -Istem istem.txt" -f $sn)
}

New-Item -ItemType Directory -Force (Join-Path $Root 'runs') | Out-Null
foreach ($a in $Adim) {
    Dur-Kontrol
    switch ($a) {
        'kontrol0' { Adim-Kontrol0 }
        'motor' { Adim-Motor }
        'model' { Adim-Model }
        'kontrol' { Adim-Kontrol }
        default { throw "bilinmeyen adim: $a (kontrol0, motor, model, kontrol)" }
    }
}
exit 0

