# VideoTurko

[English](README.md) · Türkçe · [简体中文](README.zh-CN.md) · [日本語](README.ja.md) · [Español](README.es.md) · [Русский](README.ru.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [العربية](README.ar.md) · [Português (BR)](README.pt-BR.md) · [Italiano](README.it.md) · [한국어](README.ko.md) · [हिन्दी](README.hi.md) · [Bahasa Indonesia](README.id.md) · [Tiếng Việt](README.vi.md) · [Polski](README.pl.md) · [Nederlands](README.nl.md) · [Українська](README.uk.md) · [فارسی](README.fa.md) · [עברית](README.he.md) · [ไทย](README.th.md) · [বাংলা](README.bn.md) · [اردو](README.ur.md) · [Ελληνικά](README.el.md) · [Čeština](README.cs.md) · [Română](README.ro.md) · [Magyar](README.hu.md) · [Svenska](README.sv.md) · [Azərbaycanca](README.az.md) · [Bahasa Melayu](README.ms.md)

![Windows](https://img.shields.io/badge/Windows-10%2F11-blue) ![GPU](https://img.shields.io/badge/NVIDIA-4%20GB%20(sm__61)-76b900) ![License](https://img.shields.io/badge/code-MIT-green) ![Status](https://img.shields.io/badge/status-clean--root%20test%20pending-orange)

> **30 saniyede:** 4 GB bir ekran kartı 209 karelik (8,7 sn) MiniMax H3 videosunu tek geçişte üretebiliyor: tek makinede doğrulandı (GTX 1050 Ti 4 GB; boş klasörde tam `kur.ps1` kurulumu uçtan uca henüz doğrulanmadı) [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kanıt yazarlarda, bu depoda yok]; `-InitImg` (resimden video) ile en çok 192 kare (8,0 sn) [ölçtüm: koşu B192]; 209 kare yaklaşık 57 dk sürer, varsayılan süre tavanı 80 dk [ölçtüm: koşu U209]; aşağıdaki 3 adım nasıl çalıştırılacağını gösterir.

VideoTurko: 4 GB GTX 1050 Ti'de MiniMax H3 ile metinden videoyu tek seferde 209 kareye (8,7 sn) kadar, resimden videoyu (`-InitImg`) 192 kareye (8,0 sn) kadar (209 kare bayt zinciriyle doğrulandı) üretmek için stable-diffusion.cpp bellek yamaları ve tarifler; 56 ve 141 karelik kontrollerde yamasız koşuyla bayt aynı.

> **Monster (RTX 2050 4 GB / sm_86) notu:** yazarın yayın ikilisi Pascal sm_61 içindir; bu depoda ayrıca **sm_86 motoru** derlenir. Kurulum ve ölçüm notları: [MONSTER.md](MONSTER.md).

## Hızlı başlangıç (Windows, 3 adım)
**Durum: aşağıdaki kurulum/çalıştırma betikleri tamamlanıyor ve temiz kök testi bekliyor; bu test geçene kadar burada hiçbir şeyin çalıştığı iddia edilmez ("Durum ve sınırlar").**

1. **İndir**: bu depoyu indirin (yeşil **Code** düğmesi, **Download ZIP**) ve KISA bir klasöre açın, örneğin `C:\vt`.
2. **Kur**: o klasörde PowerShell açın (Gezgin adres çubuğuna `powershell` yazın) ve çalıştırın:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\kur.ps1
   ```
   Kurulum kökü açtığınız klasördür (motor `engine\bin`, modeller `model` altına gider); başka yer için önce `VT_ROOT` ortam değişkenini ayarlayın. GPU, sürücü, RAM ve disk kontrol edilir; motor ve modeller indirilir (motor zipleri ve yeni indirilen model dosyaları sha256 ile doğrulanır; boyutu doğru olan mevcut model dosyası yalnız boyutla denetlenir, tam sha256 için `scripts\modelleri_indir.ps1 -Dogrula`); kısa gerçek bir kontrol koşulur ve yalnız o geçerse HAZIR yazar [tasarım: `kur.ps1` temiz klasörde baştan sona koşulmadı; temiz kök testinden sonra bu cümle güncellenir]. `-ExecutionPolicy Bypass` yalnız bu sürece uygulanır; her kurulum betiğinde olduğu gibi önce `scripts\kur.ps1`'i okuyun.
   Release yayınlanana kadar motor adımı "release adresi/sha256 henuz yok" diyerek durur; yerel zip verin: `-MotorZip <path> -CudaZip <path>`. Yerel zip ve henüz gömülü release sha256'sı yokken zipin yanındaki `.sha256` kullanılır; bu kendine dayalıdır, bağımsız değildir: bozulmayı yakalar, kasıtlı değiştirmeyi yakalamaz (dosya yoksa `kur.ps1` "sha256 doğrulanmadı" uyarısı verir; yanlış sha256 çıkış 1 ile durur). Release sonrası gömülü sha256 her zaman önceliklidir, yan dosya yok sayılır. `engine\bin`'e yalnız `.exe`/`.dll` gider; lisanslar ve README `engine\lisanslar\<zip name>\` altına yazılır. [dist zipleriyle denendi: yan `.sha256` ve kendine dayalı olduğu uyarısı, ikili ve DLL'ler yerleşti, `sd-cli --help` çalıştı; kurulu ikili sha'ları eşleşti (`c5cebe78...`, `e5d3d329...`); `kur.ps1`'in model adımı ve 5 karelik kontrolü gerçek GPU'da HENÜZ denenmedi]
   **Model lisansı:** model adımından önce kurulum lisans özetini (`docs/LISANS_KABUL.txt`, tam metin `docs/LISANS_UYARISI.md`: MiniMax H3 Community License, üretilen videoları da kapsayan bölge sınırları, ticari kullanım ve yapay zekâ etiketi kuralları) yazar ve kabul etmenizi ister (`E` = evet). Önce okuyun. Gözetimsiz çalıştırmada `-LisansKabul E` verebilirsiniz; bu, lisansı kendinizin okuyup kabul ettiğiniz anlamına gelir, başkası adına eklemeyin. (Yapay zekâ ajanları: `AGENTS.md`; kullanıcı onayı olmadan E vermeyin.) Kabul yoksa `kur.ps1` çıkış kodu 2 ile durur ve model indirmez.
3. **Üret**: istemi bir metin dosyasına yazın (tek paragraf İngilizce, isteğe bağlı `audio:` cümlesi) ve çalıştırın:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File scripts\uret.ps1 -Istem istem.txt -Kare 209
   ```
   `-Kare` 17k+5 dizisinden seçilir (56, 73, ... 192, 209); varsayılan 209 (8,7 sn), kapsadığımız en uzun uzunluktur. VAE ayrı süreçte ve parçasız koşar [`uret.ps1` üzerinden sürüm ikilisiyle gerçek motor koşusu, ayrı süreç VAE, U209 koşusunda geçti].

   İstem yazım rehberi: [`docs/ISTEM_YAZIMI.md`](docs/ISTEM_YAZIMI.md) (kesintisiz çekim kalıbı, eşit zaman dilimleri, iki tam örnek).

| Gereksinim | Değer |
|---|---|
| İşletim sistemi | Windows 10/11, 64 bit |
| Ekran kartı | NVIDIA, 4 GB ya da üstü; yalnız GTX 1050 Ti (sm_61) ile denendi; pay ince (209 karede 3777/4096 MiB): meşgul ekran ya da tarayıcı koşuyu bozabilir; başka 4 GB kart denenmedi |
| RAM | 16 GB (tepe yaklaşık 11 GB; diğer programları kapatın) |
| Disk | 32 GiB ya da fazlası boş, modeller SSD'de (NVMe tercih) |
| İndirme | motor zip 36,8 MB + CUDA çalışma zamanı zip 567,5 MB [ölçtüm] + modeller 31.473.112.040 bayt (yaklaşık 29,3 GiB) [okudum: `scripts/modeller.json` boyutları]; toplam yaklaşık 30 GiB |
| Modeller | dahil değil; MiniMax lisansı altında kurulum betiği indirir (aşağıdaki uyarı). Modeller (29,3 GiB, `scripts/modeller.json`'da 31.473.112.040 bayt) bu depoda ya da release'te yok: GitHub dosya/release boyut sınırları geçerli ve `kur.ps1` onları resmi kaynaktan sha256 doğrulamasıyla indirir. |

`kur.ps1` çıkış kodları: 0 HAZIR, 1 hata, 2 kullanıcı girdisi gerekli (lisans ya da henüz release/zip yok), 3 donanım ya da disk yetersiz, 4 durduruldu (DUR dosyası). `uret.ps1` bir koşuyu yalnız `.avi` var, kare sayısı doğru ve loglar temizse kabul eder [ölçtüm: sürüm ikilisiyle `uret.ps1` üzerinden bir gerçek koşu, koşu U209, 209 kare, kapı geçti]. `uret.ps1` çıkış kodları: 0 TAMAM (kalite kapısı geçti), 1 hata ya da geçersiz çıktı (ses akışı olmayan video dahil), 2 durduruldu (DUR dosyası), 5 `KAPI RED` (kalite kapısı geçmedi: klip kabul edilmez, karar sizin), 6 kapı çalışamadı (klip kabul edilmez). Ayrıntı AGENTS.md'de. [ölçtüm: çıkış kodları 0, 1 (sessiz video), 5 ve 6 sahte motor ve sahte kapıyla senaryolarda; gerçek motor: U209 koşusunda çıkış 0]

### Sorun giderme (ayrıntı: `docs/SIK_HATALAR.md`)
| Ne görüyorsunuz | Ne demek, ne yapılır |
|---|---|
| `STATUS_DLL_NOT_FOUND` / `cudart64_12.dll not found` (#13) | `sd-cli.exe`'yi elle başlatmayın; CUDA DLL'lerini yerine koyan `scripts\kur.ps1`'i çalıştırın. |
| `blocks.0` `failed during weight preparation` (#1, #3, #5) | Bellek kapısında VRAM yetmedi: 17k+5 dizisinden daha küçük kare sayısı seçin, diğer GPU programlarını kapatın, verilen bayrakları değiştirmeyin. |
| `retrying with temporal tiling` (#6) | VAE parçalı moda düştü; çıktı kalite açısından geçersiz. Yeniden çalıştırın. |
| Süre tavanında durdu, video yok (#7) | Uzun klipler için `-TavanDk` değerini artırın (varsayılan süre tavanı 209 kare için 80 dk, `uret.ps1` ayarlar; 209 karelik koşumuz 57 dk sürdü [ölçtüm: koşu U209]). |
| Çıkış kodu boş ama "bitti" yazdı (#14) | Sarmalayıcı çıkış kodunu erken okudu; yeniden çalıştırın ve video dosyasının varlığına bakın. |
| Sistem yavaşladı, takas (#18) | Motor yaklaşık 10-11 GB RAM kullanır; tarayıcı ve diğer programları kapatın. |
| sha256 tutmadı / indirme başarısız | Genelde yarım kalan indirme: aynı komutu tekrar çalıştırın, doğrulanmış dosyalar atlanır. |

## Bu nedir
MiniMax H3'ü (33B DiT; biz HyperFlow Flash 13,7B Q4_K_M GGUF'u çalıştırıyoruz; 32B Qwen3-VL metin kodlayıcı ayrıdır) 4 GB'lık Pascal ekran kartında (GTX 1050 Ti, 16 GB RAM) çalıştırmak için küçük bellek/zamanlama yamaları, çalıştırma tarifi, kontroller ve ölçümler.
- Gerçekten ürettiğimiz ve kalite kapılarından geçen tek geçiş uzunlukları: 640x384, 24 fps, 56, 141, 158, 175, 192, 209 kare (209 kare = 8,7 sn); sesi H3'ün kendisi üretir [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kanıt yazarlarda, bu depoda yok]. 209, izleyip düzgün bulduğumuz en uzun süredir [kullanıcı bildirdi, 2026-11-19, video baştan sona izlendi; dosya: F209V2 çıktısı, 8,708 sn].
- **Bayt aynılık iddiası dürüst kapsamda:** yamasız referansa bayt aynılık yalnız 56 ve 141 karede doğrulandı. 158/175/192/209 karede aynı bayraklar ve aynı ikili zinciri kullanıldı, doğrudan bayt referansı yok (yamasız sürüm bu uzunlukları bu kartta koşamıyor).
- Kalite ayarları düşürülmez: aynı model/nicemleme, 6 adım, cfg 1, 640x384, aynı tohum, parçasız VAE.
- "İlk" iddiası yok: aradık, 4 GB'ta benzer dış örnek bulamadık; bu, yok olduğunun kanıtı değildir.

## Düzen
- `patches/` (sabit stable-diffusion.cpp commit'ine yamalar; notlar orada)
- `scripts/` derleme, çalıştırma, ayrı süreç VAE, kapı/tutarlılık yardımcıları (`doku_norm.py`: ölçek notu için aşağıya bakın)
- `docs/KURULUM.md` donanım, derleme ve çalıştırma adımları (EN+TR)
- `docs/YAMALAR.md` yama listesi, `docs/KANITLAR.md` kanıt, `docs/KAPILAR.md` kalite kapıları tablosu, `docs/OLCUMLER.md` ölçümler, `docs/SIK_HATALAR.md` sık hatalar, `docs/LISANS_UYARISI.md` lisans maddelerinin tamamı
- `scripts/` kısa dizin: `hiz_kos3.ps1` çalıştırma sarmalayıcısı (`-Kuru` tam komutu yazdırır), `uretim_kapi.ps1` kalite kapısı, `dikis_denetim.py` dikiş denetimi, `doku_norm.py` dokuya göre normalize gürültü, `bayt_kiyas.py` bayt karşılaştırma, `derleme_sablonu.ps1` derleme şablonu (yalnız kendi derlemesinden sonra başlayan Visual Studio telemetri yardımcısı `vctip.exe`'yi kapatır; aksi halde derleme sürecini dakikalarca bağlı tutar; diğer `vctip.exe` süreçlerine dokunulmaz)

## Kalite kapıları

Bu kapı hareket tutarlılığını (nesne ölçeği/konum sıçraması) denetlemez: kabul etmeden önce videonun tamamını izleyin.
1. Kare sayısı doğru, ses var, günlükte bellek geri-düşme/ALLOC_FAILED satırı yok.
2. Ham gürültü kapısı: medyan süzgeç artığı <= 1,5 (0-255).
3. Dokuya göre normalize gürültü, `scripts/doku_norm.py` (bu deponun sürümü): N = medyan artık / Sobel doku, her 6. kare. **Ölçek notu:** bu sürümde ölçülen 10 klip N = 0,034-0,052 verir (tablo `docs/KAPILAR.md`; F192/F209V2 son çeyrek 0,062'ye çıkar), ek kapı eşiği N <= 0,065. Başka bir gerçekleme aynı kliplerde 0,028-0,036 ölçtü, yani eşikler sürümler arasında DEĞİŞTİRİLEMEZ. Çok ince dokuda (çim sırası) temiz N 0,075 çıktı: eşik sahne ailesine göre. Önerilen ek kapı: yüksek frekans bandı sağlam gürültü tahmini (sigma-HH <= 1,5; temiz 0,74-1,19, s=2 gürültüde 2,2-3,0).

Kapsam: VideoTurko TEK geçiş içindir (209 kareye kadar, yaklaşık 8,7 sn). Parçaları birleştirip uzun video yapmak denendi; dikişler belli oldu (sahne temiz devam etmiyor), bu yüzden projenin parçası değil. Daha uzun video isteyen kendi çözümünü geliştirebilir.
Ayarlar sizin: 209 kare bizim 4 GB kartta denediğimiz varsayılandır, zorunlu değil. 17k+5 dizisinden istediğiniz kare sayısını seçin (56, 73, ... 192, 209; bkz. `docs/KURULUM.md`); istemi, tohumu, çözünürlüğü ya da herhangi bir bayrağı istediğiniz gibi değiştirin. Kısa video daha az bellek ve süre ister; büyük kartta daha fazlası sığabilir.

## Model lisans uyarısı
**VideoTurko yalnız yamalar ve betikler içerir (MIT); modeli ve çıktıları kullanan kişi MiniMax lisansından kendisi sorumludur.** Hukuki görüş değildir. Aşağıda MiniMax H3 Community License (2 Ağustos 2026) maddeleri numaralarıyla özetlenmiştir; bağlayıcı olan lisansın kendisidir: https://huggingface.co/MiniMaxAI/MiniMax-H3/blob/main/LICENSE

Bu depo model ağırlığı İÇERMEZ (MiniMax H3, HyperFlow-H3-Flash GGUF ve VAE dosyaları yok). Bu proje MiniMax ile bağlantılı ya da onaylı değildir. Ticari kullanım yasak DEĞİLDİR (lisans ticari-olmayan lisansı değildir); şartlar aşağıdadır.

**Bölge (Applicable Territory)**
- **Giriş, I.3, I.5:** Lisans dünya geneli, ama Avrupa Birliği, Birleşik Krallık, Güney Kore ve ABD HARİÇ. Modeli kullanmaya başlamak lisansı kabul etmek sayılır.
- **II:** Telifsiz, devredilemez, sınırlı lisans; kullanma, çoğaltma, dağıtma, türev üretme ve değiştirme yalnız bu bölgede ve sözleşme ile Ek A'ya uyarak serbesttir. Hariç bölgelerdeki kişiler MiniMax'tan ayrı lisans isteyebilir.
- **V.4:** Modeli, türevlerini VE ÇIKTILARI (ürettiğiniz video/ses) hariç bölgelerde kullanmak, çoğaltmak, değiştirmek, dağıtmak ya da göstermek yetkisizdir. **Yani üretilen videoyu AB/BK/Güney Kore/ABD'de yayınlamak ya da göstermek lisans dışıdır.**
- **Ek A-1:** Bölge dışı kullanım, kabul edilebilir kullanım politikasının ihlalidir.

**Dağıtım (III)** (bu depo model dağıtmaz; modeli dağıtırsanız)
- **III.1:** Her alıcıya lisansın kopyasını verin. **III.2:** Değiştirdiğiniz dosyalara belirgin değişiklik notu koyun.
- **III.3:** Teşvik edilir (zorunlu değil): ürüne "Powered by MiniMax H3" notu, üretilen dosyalara yapay zekâ etiketi, herkese açık bir yazı.
- **III.4:** Dağıtıma şu metni içeren bir NOTICE dosyası eşlik ETMEK ZORUNDADIR: "MiniMax H3 is licensed under the MiniMax H3 Community License Agreement, Copyright © 2026 MiniMax. All Rights Reserved."
- **Ek A-12:** makine üretimi olduğunu açıkça söylemeden herkese açık ortama içerik yayma yasaktır: yapay zekâ ile üretilen videoları yayımlarken etiketleyin (tam liste: `docs/LISANS_UYARISI.md`).
- **III (son paragraf):** Değişikliklerinize kendi telifinizi koyabilirsiniz ama kullanım/dağıtım için ek ya da farklı şart koyamazsınız; bölge kuralları geçerli kalır.

**Ticari şartlar (IV)**
- **IV.1:** Ticari ürün/hizmetleriniz yıllık 20 milyon ABD dolarından (ya da karşılığından) fazla gelir getiriyorsa api@minimax.io adresinden ("MiniMax H3 licensing - authorization request" konusuyla) ÖNCEDEN yazılı izin alın.
- **IV.2:** Modeli kullanan ticari ürün/hizmetin arayüzünde "MiniMax H3" belirgin yazılmalıdır.

**Kullanım kısıtları (V)**
- **V.1:** Yürürlükteki yasalara (ticaret/ihracat uyumu dahil) ve Ek A'ya uyun. **V.2:** Modele erişim verdiğiniz herkesi en az bu kısıtlar kadar koruyucu bağlayıcı şartlara bağlayın ve onlara bildirin.
- **V.3:** Modeli ya da ÇIKTILARINI başka bir yapay zekâ modelini geliştirmek için kullanamazsınız (yalnız MiniMax H3 ve türevleri hariç). (I.11: damıtma ve sentetik veriyle eğitim de "türev" sayılır; çıktının kendisi türev sayılmaz.)
- **V.5:** Üçüncü kişilere model ile çıktı ürettiren bir ürün/hizmet/barındırılan hizmet sunarsanız: önce ve süresince makul teknik ve kurumsal güvenlik önlemleri, ihlal bildirim mekanizması, bildirimde hızlı inceleme, içerik kaldırma/erişim kesme ve tekrarlayanı askıya alma yükümlülüğü.

**Marka ve haklar (VI)**
- **VI.1:** Yaptığınız türev işlere ve model türevlerine (MiniMax'ın haklarına tabi) siz sahipsiniz. **VI.2:** MiniMax adı/markası lisanslı değil (yalnız modeli anlatmak/dağıtmak için gerekli ölçüde); "MiniMax H3" markası yalnız III.3 uyumu için bölge içinde kullanılabilir; ortaklık ima etmeyin.
- **VI.3:** MiniMax'a ya da başkasına, materyalin/çıktının hakkınızı ihlal ettiği iddiasıyla dava açarsanız tüm lisanslarınız o gün sona erer; modelin sizce ya da başkalarınca kullanım/dağıtımından doğan üçüncü kişi taleplerinde MiniMax'ı savunur ve tazmin edersiniz.
- **VI.4:** MiniMax çıktılar üzerinde hak iddia etmez; çıktıdan ve sonraki kullanımından siz ve kullanıcılarınız sorumlusunuz.

**Sorumluluk reddi ve fesih (VII, VIII, IX)**
- **VII.1:** MiniMax destek/güncelleme/yeni sürüm vermek zorunda değil. **VII.2:** Model ve çıktılar "OLDUĞU GİBİ", garantisiz; uygunluğu belirlemek ve riski üstlenmek size ait. **VII.3:** MiniMax ve bağlıları hiçbir zarardan sorumlu değildir (yasanın izin verdiği ölçüde).
- **VIII.1:** Sözleşme kabul/erişim anında başlar. **VIII.2:** İhlalde MiniMax feshedebilir; fesihte model kullanımını/dağıtımını hemen bırakır, kopyaları silersiniz ve alıcıları bilgilendirirsiniz (VI.1, VI.3, VII, IX fesihten sonra da sürer).
- **IX:** Hukuk Hong Kong ÖİB hukukudur; yetkili mahkemeler Hong Kong mahkemeleridir (BM Mal Satımı Sözleşmesi uygulanmaz).
- **Ek not:** MiniMax H3 kodlayıcısı Qwen3-VL-32B (Apache 2.0) kullanır.

**Kabul edilebilir kullanım politikası (Ek A)** (modeli, türevlerini ve çıktıları şunlar için KULLANMAYIN)
- A-1 bölge dışı kullanım; A-2 yasaları ya da üçüncü kişilerin fikri haklarını ihlal; A-3 kendinize/başkasına zarar; A-4 çıktıyı zarar vermek için yeniden kullanma/dağıtma; A-5 güvenlik önlemlerini aşma; A-6 reşit olmayanları sömürme/zarar; A-7 zarar vermek ya da seçimleri etkilemek için doğrulanabilir biçimde yanlış bilgi; A-8 sahte çevrimiçi etkileşim (sahte yorum vb.); A-9 iftira, aşağılama, taciz; A-10 kötü amaçlı yazılım; A-11 zarar vermek için kişisel veri; **A-12 makine üretimi olduğunu açık ve belirgin söylemeden herkese açık ortama (bot gönderileri dahil) içerik yayma**; A-13 rızasız başkasını taklit; A-14 kritik alanlarda (kolluk, göç, sağlık, kritik altyapı, kredi, istihdam, konut, eğitim, sosyal puanlama, sigorta vb.) yüksek riskli otomatik karar; A-15 başka ülke/bölgelerin toplumsal, etik, ahlaki değerlerini ihlal; A-16 şiddet içerikli aşırıcılık/terör; A-17 korunan özelliklere dayalı ayrımcılık/zarar; A-18 savunmasız grupların zayıflığını istismar; **A-19 askeri amaç**; A-20 izinsiz/ruhsatsız mesleki faaliyet (finans, hukuk, tıp vb.).
- Not: Bu metin sade dilde özettir; belirsizlikte lisansın İngilizce metni geçerlidir.

## Kanıt etiketleri

Tüm belgelerde tek set (eski yazımlar parantezde):
- **[ölçtüm]** (EN: measured, olctum): bu projede koşuldu, kanıt yolu var.
- **[okudum]** (EN: read; eski yazım: okudum yol): kaynak ya da betik okundu, koşulmadı.
- **[tasarım]** (EN: design, tasarim): tasarlandı, gerçek koşuda görülmedi.
- **[tahmin]** (EN: guess): doğrulanmadı.
- **[denenmedi]** (EN: not tried): hiç koşulmadı.
- **[kullanıcı bildirdi]** (EN: user-reported): kullanıcı söyledi, tarihli; bağımsız ölçülmedi.
- **[hesap]** (EN: computed; eski yazımlar: calculated): ölçülen girdilerden türetilmiş sayı, kendisi ölçülmedi; hesap yolu yanında yazılı. Eski metindeki [öneri] / [proposal] = [tahmin].

Köşeli parantezde geçen koşu adları (bize ait koşu adları, bu depoda dosya değil): U209 = sürüm ikilisiyle `uret.ps1` üzerinden 209 kare; B209 ve B192 = resimden video (`-InitImg`) 209 ve 192 kare koşuları; B56VT2 = sürüm ikilisi, 56 kare, 56 karelik bayt referansı R0 ile kıyas; F209b, F209V2, F209V2K = geliştirme derlemesinde 209 karelik koşular (ayrıntı: `docs/OLCUMLER.md`).

## Bilinen sınırlar
- **Bayt kanıtı** (kendiniz nasıl üretirsiniz: `docs/KANITLAR.md`, "R0 ve latent referansi nasil uretilir"; sm_61 kartımızda doğrulandı, başka GPU'larda bayt aynı olmayabilir [tahmin]): yama serimizle (bellek bayrakları açık) 56 karelik koşu referansla aynı sha256 `0979f156d548169b...` verdi [ölçtüm]; 141 karede latent sha256 `E5D028F8632BE4FE...` aynı çıktı (0013/0014 bayraklarıyla). 158-209 karede doğrudan bayt referansı yok; kanıt kapı zinciridir. Sayısal kapılardan geçmek iyi klip garantisi vermez: zaman içinde hareket tutarlılığı gözle denetlenir (`docs/KAPILAR.md`).
- **209 kare, hangi bayrak seti:** 209 karelik bayt zinciri kanıtı geliştirme derlemesinde F209V2 bayrak setiyle alındı (blok-sonu bayrağı yok, 0019/0020 yamasız derleme); `uret.ps1` 209 kare için bu tarifi kullanır [okudum: betik; `uret.ps1` üzerinden gerçek motor koşusu U209'da geçti].
- Tek kartta doğrulandı (GTX 1050 Ti 4 GB); başka kartlar denenmedi.
- **Hangi ikili ölçüldü:** 141 kare latent ve bayt zinciri geliştirme derlemelerimizle ölçüldü. İndirdiğiniz sürüm ikilisi yeni bir derlemedir: 56 kare bayt kapısı geçti (sonraki madde) ve `uret.ps1` üzerinden 209 kare koşusu kapıyı geçti (koşu U209, 3414 sn, VRAM tepesi 3777 MiB) [ölçtüm]; geliştirme derlemesi 209 koşusuyla latent bayt-aynı; videoda kareler (md5) ve ses aynı, AVI dosya sha256'sı konteyner nedeniyle farklı [ölçtüm] (`docs/OLCUMLER.md`, bölüm 0).
- **Sürüm ikilisi, 56 kare:** sürüm ikilisi (sd-cli `c5cebe78...`, stable-diffusion.dll `e5d3d329...`) 56 karede R0 ile bayt aynı sonuç verdi (sha256 `0979f156d548169be03acd1a9d7617102a75333aa48a28d6bbfd1cc5fa3f604d`; kare md5 ve ses aynı); doğrudan, varsayılan bayraklarla (hiç `SD_*` yok), çıkış kodu 0, 601 sn [ölçtüm: koşu B56VT2, 2026-11-19; kanıt yazarlarda, bu depoda yok]. Kapsam: yalnız sm_61 kartımız ve 56 kare; temiz kök kurulum testi değil; 141 kare latent ve 209 zinciri eski ikiliyle ölçüldü, bununla TEKRARLANMADI [denenmedi]. İlk deneme (B56VT, yardımcı betikle) 58 sn'de sessizce bitti, neden bilinmiyor [tahmin: bellek baskısı]; ikinci deneme `sd-cli`'yi doğrudan çalıştırdı.
- Kurulum ve çalıştırma betikleri boş klasörde henüz doğrulanmadı (temiz kök testi bekliyor).
- Yol haritası ve sonraki adımlar: `ROADMAP.md`.

## Durum ve sınırlar
- Tek makinede doğrulandı (GTX 1050 Ti 4 GB, 16 GB RAM, i7-7700HQ). Başka 4 GB kartlar ve RAM boyutları farklı olabilir.
- **Varsayılan 209 kare (8,7 sn):** kalite kapılarından geçti (gürültü 1,08, koşu F209V2K) [ölçtüm: 209 kare, sürüm ikilisiyle, `uret.ps1` üzerinden, koşu U209; latent bayt-aynı; videoda kareler ve ses aynı, dosya sha'sı konteyner nedeniyle farklı; kanıt yazarlarda, bu depoda yok]. 209 karede DiT VRAM tepesi 4096 MiB içinde 3777 MiB idi (koşular F209b ve U209; tüm kart için `nvidia-smi` okuması), pay ince: başka GPU yükü (ekran, başka uygulamalar) koşuyu `blocks.0`'da düşürebilir; yalnız GTX 1050 Ti'de denendi. O koşuda ekran durumu kayıtlı değil; ekranınız bu karta bağlıysa kullanılabilir VRAM daha azdır [tahmin: Windows ekran yükü yaklaşık 100-300 MB]; gerekirse ekranı tümleşik GPU'ya bağlayın [tavsiye, denenmedi]. Örnekleme 2730 sn (U209: adımlar 436-483 sn), ayrı süreç VAE çözmesi 173 sn sürdü (2. aşama toplam 193 sn, ses çözme dahil) [ölçtüm: U209 sürüm ikilisi; eski geliştirme koşuları: 2664 sn ve 174 sn]. 1. aşamada süreç içi VAE belleği aşıp parçalı çözmeye düştü (320 sn); o çıktı atılır, video parçasız 2. aşamadan gelir. U209'da RAM tepesi ölçülmedi. 209 karedan uzun klipler bu sürümün parçası değil.
- **Resimden video (`-InitImg`):** başlangıç resmiyle bu GPU'da tavan 192 karedir (24 fps'te 8,0 sn): 209 kare sığmadı (blok 0'da yaklaşık 17,5 MB VRAM eksik: gereken 2587 MB, boş 2570 MB); 192 kare `uret.ps1` ile 3086 sn'de koştu, VRAM tepesi 3783 MiB, kapı geçti [ölçtüm: B209 ve B192 koşuları, 2026-11-20, tek sahne; kanıt yazarlarda, bu depoda yok]. Başka GPU'lar: [denenmedi].
- **Boş RAM önemli:** yaklaşık 11 GB BOŞ RAM gerekir (motor süreci yaklaşık 11 GB tutar) [ölçtüm]. Boş RAM azsa süreç hata mesajı vermeden ölebilir [tahmin: bir kez gözledik, boş RAM yaklaşık 300 MB iken `sd-cli` yaklaşık 10 GB tutuyordu]. Koşu sürerken başka büyük program açmayın: 16 GB'lık makinede boş pay yalnız yaklaşık 0,3-0,5 GB kalır ve bellek baskısında koşu sessizce ölebilir. Başlamadan önce tarayıcı, oyun ve diğer büyük programları kapatın, boş RAM'e bakın.
- **Temiz kök testi bekliyor:** kurulum ve çalıştırma betikleri boş klasörde yalnız bu talimatla henüz doğrulanmadı; test (56 karede referansa bayt kıyası dahil) kaydedilince bu bölüm güncellenir.
- Çıktı videolar depoda yok.

<!-- i18n-source: README.md sha256:a72e4a0b2471 -->
