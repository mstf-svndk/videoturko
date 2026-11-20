# VideoTurko — Monster (RTX 2050 4 GB) sürümü

Bu depo, [alexturkey/VideoTurko](https://github.com/alexturkey/VideoTurko) projesinin **bağımsız arşiv kopyasıdır** (yazar silse de kalır). Bu sayfa yalnız **Monster Abra A5 (RTX 2050 4 GB, Ampere sm_86)** için yapılan ekleri anlatır. Orijinal belgeler olduğu gibi geçerlidir: `README.tr.md`, `docs/`.

## Neden ek iş gerekti
Yazarın yayınladığı motor yalnız **Pascal sm_61** (GTX 1050 Ti) için derlenmiş; RTX 2050'de (sm_86) çalışmaz — CUDA "no kernel image is available" hatası verir. Bu depoda **kendi sm_86 derlememiz** var:

- Derleme hattı: `.github/workflows/derle-engine-sm86.yml` (GitHub Actions, windows-2022 + CUDA 12.8)
- Taban: stable-diffusion.cpp `32d516c` + ggml `d803c238` — yazarın sabitlediği commit'ler
- Yamalar: `patches/` serisi, `patches/SERIES.txt` sırasıyla (24 yama, hepsi varsayılan kapalı)
- Kalite ayarları değişmedi: 640x384, 24 fps, 6 adım, cfg 1, parçasız VAE

## Beklenen donanım
| | |
|---|---|
| Makine | Monster Abra A5 V21.3 |
| Ekran kartı | RTX 2050 4 GB (sm_86, sürücü CUDA 12.8 uyumlu olmalı: ≥ 550) |
| CPU | i7-12700H (14 çekirdek / 20 iş parçacığı) |
| RAM | 32 GB (motor ~11 GB tutuyor; bol pay) |
| Disk | en az 32 GiB boş, modeller **NVMe'de** |

## Kurulum (3 adım)
```powershell
# 1) depoyu al
git clone https://github.com/mstf-svndk/videoturko.git C:\vt
cd C:\vt

# 2) kur (motor + CUDA DLL + 29,3 GiB model; lisans kabulu sorulur)
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur-monster.ps1

# 3) üret
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem istem.txt -Kare 192
```

`kur-monster.ps1`, yazarın `kur.ps1`'ine **yalnızca indirme adreslerini** verir (sm_86 motor zip'i + CUDA çalışma zamanı zip'i, ikisi de bu deponun sürümünde, sha256 gömülü) ve eski/sm_61 motor kuruluysa onu yeniler. `kur.ps1`'in kendi denetimleri, çıkış kodları ve `HAZIR` kontrol üretimi aynen geçerli.

**İlk iş 56 kare ile test et** (17k+5 dizisi: 56, 73, ..., 192, 209):
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem istem.txt -Kare 56
```

## Beklenen süreler (tahmin — ölçülmedi)
1050 Ti ölçümlerinden ölçeklenmiş hesap (yazarın `docs/OLCUMLER.md` aşama süreleri):

| Kare | Süre (video) | 1050 Ti ölçümü | Monster tahmini |
|---|---|---|---|
| 56 | 2,3 sn | ~10 dk | ~5-6 dk |
| 192 | 8,0 sn | ~43 dk | **~18-22 dk** |
| 209 | 8,7 sn | ~51 dk | ~21-26 dk |

Kazanç ~2,2 kat: çekirdek sayısı 2,7 kat ama bellek yolu iki kartta da ~112 GB/s ve bu hat modeli ağırlıkları host RAM'den akıtıyor.

## Sınırlar ve riskler
- **4 GB VRAM aynen duruyor:** yazarın 209 karede ölçtüğü tepe 3777/4096 MiB. Ekran RTX 2050'ye bağlıysa pay daralır — **dahili GPU'da (Optimus) bırakın**.
- **Bu ikili GPU'suz sunucuda derlendi:** sm_86 çekirdek görüntüsü doğrulandı ama Monster'da gerçek koşu henüz ölçülmedi. İlk 56 kare koşusu bunu kesinleştirir.
- `blocks.0 failed during weight preparation` → VRAM yetmedi: daha küçük kare sayısı seçin, tarayıcı/oyun kapatın.
- Model **HDD'de olmaz**: ilk adımlar 15-25 kat yavaşlar.
- Süre tavanı: `uret.ps1` 209 kare için 80 dk veriyor; daha uzun sürerse `-TavanDk` artırın.
- `hiz_kos3.ps1` (geliştirici sarmalayıcısı) VRAM'i 3890 MiB üstünde görürse koşuyu keser; gerekirse `VT_VRAM_ABORT_MB` ile eşiği değiştirin.

## Lisans (değişmedi)
Kod MIT; **model MiniMax H3 Community License**. Bölge kısıtı: AB, Birleşik Krallık, Güney Kore ve **ABD** dışında kullanım/yayın için lisans yok — üretilen videoyu bu bölgelerde göstermek de kapsam dışı. Yapay zekâ üretimi etiketi zorunlu (A-12). Ayrıntı: `docs/LISANS_UYARISI.md`.

## Sürümler
| Dosya | sha256 |
|---|---|
| `videoturko-motor-0.1.0-win64-cuda12.8-sm86.zip` | `b521a8c263c9ba4b64bce0a2d18e9a490c154be9dab4ecdd03fc7ade1ad669b6` |
| `videoturko-cuda-runtime-12.8-win64.zip` | `344a0b04f043fb9cccdfe38ec77716afb59bafb894f11f0fac2365f151777355` |

Motoru kendin yeniden derlemek için: Actions → **derle-engine-sm86** → Run workflow (`cuda_arch=86`).

## Geri alma
`engine\bin` klasörünü silin, `scripts\kur-monster.ps1` ile yeniden kurun. Modeller (`model\`) silinmez.
