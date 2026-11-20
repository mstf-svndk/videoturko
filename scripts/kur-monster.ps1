# kur-monster.ps1 — Monster (RTX 2050 4 GB, sm_86) icin kurulum sarmalayicisi.
#
# Ne yapar: yalnizca INDIRME ADRESLERINI kur.ps1'e verir (bu deponun sm_86 motor zip'i +
# CUDA calisma zamani zip'i, sha256 gomulu), sonra yazarın kur.ps1'ini aynen calistirir.
# Eski/sm_61 motor kuruluysa once onu temizler; basarili kurulumda engine\bin\.motor-sm86
# dosyasina sha256 yazar (sonraki calistirmalarda motor atlanir).
#
# Kullanim (depo klasorunde):
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur-monster.ps1
#   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur-monster.ps1 -Adim kontrol0,motor -Kuru
# Tum parametreler kur.ps1'e aynen gecer (-Adim, -Kuru, -LisansKabul, -MotorZip, -CudaZip, -ModelKlasoru, -Zorla).
param(
    [Parameter(ValueFromRemainingArguments = $true)] $Kalan
)

$ErrorActionPreference = 'Stop'

# --- Bu deponun surumleri (mstf-svndk/videoturko) -----------------------------
$Surum = '0.1.0'
$Tag = 'v0.1.0-sm86'
$MotorAd = "videoturko-motor-$Surum-win64-cuda12.8-sm86.zip"
$MotorSha = 'b521a8c263c9ba4b64bce0a2d18e9a490c154be9dab4ecdd03fc7ade1ad669b6'
$CudaAd = 'videoturko-cuda-runtime-12.8-win64.zip'
$CudaSha = '344a0b04f043fb9cccdfe38ec77716afb59bafb894f11f0fac2365f151777355'
$Taban = "https://github.com/mstf-svndk/videoturko/releases/download/$Tag"

# kur.ps1 bu ortam degiskenlerini gomulu degerlere tercih eder (bkz. scripts\kur.ps1).
$env:VT_MOTOR_ZIP_AD = $MotorAd
$env:VT_MOTOR_URL = "$Taban/$MotorAd"
$env:VT_MOTOR_SHA256 = $MotorSha
$env:VT_CUDA_URL = "https://github.com/mstf-svndk/videoturko/releases/download/v0.1.0/$CudaAd"
$env:VT_CUDA_SHA256 = $CudaSha

$Root = $(if ($env:VT_ROOT) { $env:VT_ROOT } else { (Resolve-Path (Join-Path $PSScriptRoot '..')).Path })
$Motor = $(if ($env:VT_ENGINE_BIN) { $env:VT_ENGINE_BIN } else { Join-Path $Root 'engine\bin' })
$Damga = Join-Path $Motor '.motor-sm86'

Write-Output "== kur-monster: sm_86 motoru (RTX 2050 4 GB) kurulacak"
Write-Output "   motor: $MotorAd"
Write-Output "   sha256: $MotorSha"

# Eski motor (yazarın sm_61 surumu ya da onceki derleme) varsa yenile.
if (Test-Path -LiteralPath (Join-Path $Motor 'sd-cli.exe')) {
    $mevcut = $(if (Test-Path -LiteralPath $Damga) { (Get-Content -LiteralPath $Damga -Raw).Trim() } else { '' })
    if ($mevcut -ne $MotorSha) {
        Write-Output '   mevcut motor sm_86 surumu degil (ya da eski derleme): ikili ve DLL dosyalari yenilenecek'
        Get-ChildItem -LiteralPath $Motor -Recurse -File -Include *.exe, *.dll -ErrorAction SilentlyContinue |
            Remove-Item -Force -ErrorAction SilentlyContinue
    }
}

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'kur.ps1') @Kalan
$kod = $LASTEXITCODE

if ($kod -eq 0 -and (Test-Path -LiteralPath (Join-Path $Motor 'sd-cli.exe'))) {
    Set-Content -LiteralPath $Damga -Value $MotorSha -Encoding ASCII
    Write-Output '   motor damgasi yazildi: engine\bin\.motor-sm86'
}
exit $kod
