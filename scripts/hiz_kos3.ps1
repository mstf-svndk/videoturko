# hiz_kos3.ps1: sd-cli kosucusu (gelistirme/olcum). Gizli baslatir, ciktiyi zaman damgali satirlara cevirir,
# 1 sn'de bir RAM + VRAM/isi ornekler; DUR dosyasi, VRAM > 3,8 GB ya da sure tavani gorunce keser; kosu oncesi/sonrasi ekran surucusu olay 4101'i sayar.
# -Kuru: tam komutu yazar, calistirmaz. Gunluk kullanim icin scripts/uret.ps1 yeterli; bu betik motor/bayrak denemeleri icindir.
param([Parameter(Mandatory)][string]$Deney, [string]$Cikti = "cikti", [string[]]$Ekstra = @(), [switch]$OlumD3, [switch]$T1, [switch]$SayacSadece, [switch]$Onisit, [switch]$OnisitTrim, [switch]$Karosuz, [string]$ChunkBudget = "0.05", [string]$MotorDizin = $(if($env:VT_ENGINE_BIN){$env:VT_ENGINE_BIN}else{""}), [string[]]$Env = @(), [int]$Threads = 4, [int]$DurAdim = 0, [switch]$OnisitTE, [string]$OutDir = "", [string]$IstemDosya = "", [string]$InitImg = "", [int]$TavanDk = 50, [switch]$Kuru, [int]$Kare = 56)
$Karosuz = $true   # uretimde HER ZAMAN karosuz VAE (karoli/yaklasik VAE yedegi yasak); kalite referansi degismesin
$ErrorActionPreference = 'Continue'
function OkuPaylasimli($f){ $fs=[IO.File]::Open($f,'Open','Read','ReadWrite'); try{ $sr=New-Object IO.StreamReader($fs); $sr.ReadToEnd() } finally { $fs.Close() } }
$Root = $(if($env:VT_ROOT){$env:VT_ROOT}else{(Resolve-Path (Join-Path $PSScriptRoot '..')).Path})
$p = $Root
$d = $(if($OutDir){$OutDir}else{"$p\runs\$Deney"}); New-Item -ItemType Directory -Force $d | Out-Null; $TE = "$p\model\qwen3vl_32b_minimax_h3-Q4_K_M.gguf"; $Parca = $Cikti; $Sigmas = "hyperflow-h3-flash-6"
if($env:VT_CUDA_BIN){ $env:PATH = "$($env:VT_CUDA_BIN);" + $env:PATH }
$ev0 = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Display';Id=4101;StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue).Count
$args2 = @('-M','vid_gen',
 '--diffusion-model',"$p\model\minimax_h3_fl2va_hyperflow_flash_14b-Q4_K_M.gguf",
 '--llm',$TE,
 '--vae',"$p\model\minimax_h3_sol_vae_fp16.safetensors",
 '--audio-vae',"$p\model\minimax_h3_audio_vae_fp32.safetensors",
 '--prompt-file',$(if($IstemDosya){$IstemDosya}else{"$p\docs\ornek_istem_R0.txt"}),'-W','640','-H','384','--video-frames',"$Kare",'--fps','24',
 '--steps','6','--sampling-method','euler','--sigmas',$Sigmas,'--cfg-scale','1.0',
 '--rng','cpu','--seed','42','-t',"$Threads",
 '--diffusion-fa','--model-args',"minimax_h3_attn_chunk_budget=$ChunkBudget",
 '--offload-to-cpu','--mmap','--backend','te=cpu',
 '--vae-tiling','--temporal-tiling',
 '--log-level','debug','-o',"$d\$Parca.avi") + $Ekstra
$argStr0 = 1; if($InitImg){ $args2 = @($args2[0..($args2.Count-3)]) + @('--init-img',$InitImg) + @($args2[($args2.Count-2)..($args2.Count-1)]) } if($Karosuz){ $args2 = @($args2 | ? { $_ -notin '--vae-tiling','--temporal-tiling' }) }
$argStr = ($args2 | ForEach-Object { if ($_ -match '[\s"]') { '"' + ($_ -replace '"','\"') + '"' } else { $_ } }) -join ' '
if ($Kuru) { $args2 | ForEach-Object -Begin {$i=0} -Process { '{0,2}: [{1}]' -f $i++, $_ } | Set-Content "$d\kuru_$Parca.txt"; ('KOMUT SATIRI: sd-cli.exe ' + $argStr) | Add-Content "$d\kuru_$Parca.txt"; foreach ($a in $args2) { if (($a -like '--*') -and $false) {} }; Add-Content "$d\kuru_$Parca.txt" ("MOTOR: $MotorDizin\sd-cli.exe var=" + (Test-Path "$MotorDizin\sd-cli.exe") + " | ENV: " + ($Env -join ' ') + " | threads=$Threads | DurAdim=$DurAdim | OnisitTE=$OnisitTE"); Write-Output "KURU: $($args2.Count) arguman, $d\kuru_$Parca.txt"; exit 0 }
foreach($e in @($Env | % { $_ -split ',' })){ $kv=$e -split '=',2; Set-Item -Path ("Env:" + $kv[0]) -Value $kv[1] }
$sp = Start-Process -FilePath "$MotorDizin\sd-cli.exe" -ArgumentList $argStr -WindowStyle Hidden -PassThru -RedirectStandardOutput "$d\ham_out_$Parca.txt" -RedirectStandardError "$d\ham_err_$Parca.txt"
$dm = $null; if($T1){ $dm = Start-Process nvidia-smi -ArgumentList 'dmon -s ut -d 1 -o T' -WindowStyle Hidden -PassThru -RedirectStandardOutput "$d\dmon_$Parca.txt" }
$t2 = $null; $adimN = 0; $t0 = Get-Date; $pos=@{out=0L;err=0L}; $zl = "$d\zamanli_$Parca.log"; $ornek = "$d\ornek_$Parca.csv"
"zaman,sn,rss_mb,vram_mib,sicaklik,sm_mhz,bos_ram_mb,disk_okuma_mbs,kullanilabilir_mb,commit_yuzde,sayfa_yazim_sn,sayfa_okuma_sn" | Set-Content $ornek
$peakR=0;$peakV=0;$peakT=0;$neden='bitti'
function Yeni($f,$k){ try{ if(!(Test-Path $f)){return}; $fs=[IO.File]::Open($f,'Open','Read','ReadWrite'); $fs.Seek($pos[$k],'Begin')|Out-Null
  $sr=New-Object IO.StreamReader($fs); $txt=$sr.ReadToEnd(); $pos[$k]=$fs.Position; $sr.Close(); $fs.Close()
  if($txt){ foreach($l in ($txt -split "`r?`n")){ if($l.Trim()){ ("{0:HH:mm:ss.f} | {1,5:N1}s | {2}" -f (Get-Date),((Get-Date)-$t0).TotalSeconds,$l) | Add-Content $zl } } } } catch { ('YENI_HATA: ' + $_.Exception.Message) | Add-Content $zl } }
$sn=0; $poN=0; $po7=0
while(-not $sp.HasExited){
  Start-Sleep -Milliseconds 1000; $sn++
  Yeni "$d\ham_out_$Parca.txt" 'out'; Yeni "$d\ham_err_$Parca.txt" 'err'
  $sp.Refresh(); $rss=[math]::Round($sp.WorkingSet64/1MB)
  $g=(& nvidia-smi --query-gpu=memory.used,temperature.gpu,clocks.sm,utilization.gpu,power.draw --format=csv,noheader,nounits) -split ','
  $vr=[int]$g[0].Trim(); $tc=[int]$g[1].Trim(); $ck=[int]$g[2].Trim()
  $free=[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1KB)
  $dk=try{[math]::Round((Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='_Total'" -ErrorAction Stop).DiskReadBytesPersec/1MB,1)}catch{-1}
  $pm=try{Get-CimInstance Win32_PerfFormattedData_PerfOS_Memory -ErrorAction Stop}catch{$null}
  $av=if($pm){[int]$pm.AvailableMBytes}else{99999}; $po=if($pm){[int]$pm.PagesOutputPersec}else{0}; $pin=if($pm){[int]$pm.PagesInputPersec}else{0}
  if($av -lt 300 -and $po -gt 100){$poN++}else{$poN=0}
  $os=Get-CimInstance Win32_OperatingSystem; $cm=[math]::Round(100*(1-$os.FreeVirtualMemory/$os.TotalVirtualMemorySize),1)
  ([string]::Format([Globalization.CultureInfo]::InvariantCulture,"{0:HH:mm:ss},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11}",(Get-Date),$sn,$rss,$vr,$tc,$ck,$free,$dk,$av,$cm,$po,$pin)) | Add-Content $ornek
  if($T1){
    try{ $tx=(OkuPaylasimli "$d\ham_out_$Parca.txt"); $mm=[regex]::Matches($tx,'(\d)/6 - '); $adimN= if($mm.Count){ ($mm | % { [int]$_.Groups[1].Value } | Measure-Object -Maximum).Maximum } else { 0 } }catch{}
    if($adimN -ge 2 -and -not $t2){ $t2=Get-Date }
    $pr=try{Get-CimInstance Win32_PerfFormattedData_PerfProc_Process -Filter "Name='sd-cli'" -ErrorAction Stop}catch{$null}
    $dc=try{Get-CimInstance Win32_PerfFormattedData_PerfDisk_PhysicalDisk -Filter "Name='0 C:'" -ErrorAction Stop}catch{$null}
    $cp=try{ Get-CimInstance Win32_PerfFormattedData_PerfOS_Processor -ErrorAction Stop | ? {$_.Name -ne '_Total'} | sort {[int]$_.Name} | % { $_.PercentProcessorTime } }catch{@()}
    $stb=if($pm){[math]::Round(($pm.StandbyCacheNormalPriorityBytes+$pm.StandbyCacheReserveBytes+$pm.StandbyCacheCoreBytes)/1MB)}else{-1}
    $satir=@((Get-Date -Format 'HH:mm:ss.f'),$sn,$adimN,$vr,$tc,$ck,[int]$g[3].Trim(),$g[4].Trim(),
      $(if($pm){$pm.PageFaultsPersec}else{-1}),$(if($pm){$pm.PageReadsPersec}else{-1}),$pin,$av,$stb,$(if($pm){[math]::Round($pm.ModifiedPageListBytes/1MB)}else{-1}),$(if($pm){$pm.CacheFaultsPersec}else{-1}),
      $(if($pr){$pr.PageFaultsPersec}else{-1}),$(if($pr){$pr.PercentProcessorTime}else{-1}),$(if($pr){$pr.IODataBytesPersec}else{-1}),$rss,
      $(if($dc){[math]::Round($dc.DiskReadBytesPersec/1MB,1)}else{-1}),$(if($dc){$dc.AvgDiskBytesPerRead}else{-1}),$(if($dc){$dc.AvgDisksecPerRead}else{-1}),$(if($dc){$dc.CurrentDiskQueueLength}else{-1}),($cp -join '/'))
    if($sn -eq 1){ "saat,sn,adim_tamam,vram_mib,sicaklik,sm_mhz,gpu_util,guc_w,sistem_pagefault_sn,sayfa_okuma_sn,sayfa_giris_sn,kullanilabilir_mb,standby_mb,modified_mb,cache_fault_sn,surec_pagefault_sn,surec_cpu_yuzde,surec_io_bayt_sn,surec_rss_mb,diskC_mb_sn,diskC_ort_okuma_bayt,diskC_ort_sn,diskC_kuyruk,cpu_cekirdek_yuzde" | Set-Content "$d\t1_sayac_$Parca.csv" }
    ([string]::Join(',',($satir | % { [string]::Format([Globalization.CultureInfo]::InvariantCulture,'{0}',$_) }))) | Add-Content "$d\t1_sayac_$Parca.csv" }
  if($rss -gt $peakR){$peakR=$rss}; if($vr -gt $peakV){$peakV=$vr}; if($tc -gt $peakT){$peakT=$tc}
  $tx=""; if($OlumD3 -and ($sn % 4 -eq 0)){ try{ $tx=(OkuPaylasimli "$d\ham_out_$Parca.txt") }catch{} }
  $mte=if($tx){[regex]::Match($tx,'get_learned_condition completed, taking ([\d.]+)s')}else{$null}; $mad=if($tx){[regex]::Match($tx,'1/6 - +([\d.]+)s/it')}else{$null}
  if($av -lt 700 -and $po -gt 100){$po7++}else{$po7=0}
  if(Test-Path "$p\DUR_TA"){ $neden='DUR dosyasi'; }
  elseif($OlumD3 -and $mte -and $mte.Success -and [double]::Parse($mte.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture) -gt 75){ $neden="olum: TE $($mte.Groups[1].Value) sn > 75" }
  elseif($OlumD3 -and $mad -and $mad.Success -and [double]::Parse($mad.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture) -gt 90){ $neden="olum: adim 1 $($mad.Groups[1].Value) sn > 90" }
  elseif($DurAdim -gt 0 -and $adimN -ge $DurAdim){ $neden="DUR: adim $DurAdim tamam (profil)" }
  elseif($T1 -and -not $SayacSadece -and $t2 -and ((Get-Date)-$t2).TotalSeconds -ge 30){ $neden='T1: adim 3 ilk 30 sn tamam, DUR' }
  elseif($OlumD3 -and $po7 -ge 3){ $neden="olum: bos RAM $av MB < 700 ve sayfa yazimi $po/sn" }
  elseif($cm -gt 90){ $neden="bellek korkulugu: commit %$cm > 90" }
  elseif($poN -ge 3){ $neden="bellek korkulugu: kullanilabilir $av MB < 300 ve sayfa yazimi $po/sn (3 ornek ust uste)" }
  elseif($vr -gt $(if($env:VT_VRAM_ABORT_MB){[int]$env:VT_VRAM_ABORT_MB}else{3890})){ $neden="VRAM $vr MiB > kesme esigi ($(if($env:VT_VRAM_ABORT_MB){$env:VT_VRAM_ABORT_MB}else{3890}) MiB, VT_VRAM_ABORT_MB)" }
  elseif(((Get-Date)-$t0).TotalMinutes -gt $TavanDk){ $neden="sure tavani $TavanDk dk" }
  if(-not $tavanUyari -and $neden -eq 'bitti' -and ((Get-Date)-$t0).TotalMinutes -gt (0.8*$TavanDk)){ $tavanUyari=$true; try{ Add-Content "$Root\runs\olaylar.txt" ("{0} | UYARI hiz_kos3: {1} sure tavaninin %80'ine geldi ({2:N0}/{3} dk), tavan asilirsa kesilir" -f (Get-Date -Format 'HH:mm:ss'),$Deney,((Get-Date)-$t0).TotalMinutes,$TavanDk) }catch{} }
  if($neden -ne 'bitti'){ Stop-Process -Id $sp.Id -Force; "KESILDI: $neden" | Add-Content $zl; break }
}
Start-Sleep 2; Yeni "$d\ham_out_$Parca.txt" 'out'; Yeni "$d\ham_err_$Parca.txt" 'err'
if($dm){ try{ Stop-Process -Id $dm.Id -Force -ErrorAction SilentlyContinue }catch{} }
if($on){ try{ Stop-Process -Id $on.Id -Force -ErrorAction SilentlyContinue }catch{} }
$sp.WaitForExit(); $sp.Refresh(); $ec = if($sp.HasExited){$sp.ExitCode}else{'?'}
$ev1 = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Display';Id=4101;StartTime=(Get-Date).AddDays(-1)} -ErrorAction SilentlyContinue).Count
$tot=((Get-Date)-$t0).TotalSeconds
"OZET: cikis=$ec neden=$neden sure_sn=$([int]$tot) rss_tepe_mb=$peakR vram_tepe_mib=$peakV sicaklik_tepe=$peakT olay4101_once=$ev0 sonra=$ev1" | Tee-Object -FilePath "$d\ozet_$Parca.txt" | Add-Content $zl























