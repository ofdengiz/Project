# Thread Gecmisi - Tam Kronoloji

Bu dosya, bu thread boyunca en bastan itibaren konusulan, denenen, duzeltilen, geri alinan ve kararlastirilan butun ana basliklari olabildigince eksiksiz ve kronolojik sekilde toplar.

Bu belge, onceki kisa ozetin genisletilmis halidir. Ama hala "ham export" degildir. Ham mesaj dump'i yerine, teknik olarak anlamli olacak sekilde yeniden duzenlenmis ayrintili bir thread kronolojisidir.

---

## 0. Baslangic Notu

Thread'in acilis durumunda ortamda zaten bazi semptomlar ve ekran goruntuleri vardi. Konusma, dogrudan bunlarin uzerinden teknik teshis yapilarak basladi.

Ilk ana odak noktasi:

- Site 2 tarafindaki Veeam backup problemleri
- DNS / port / firewall / repository / agent / credential karmasasi
- sonrasinda dokumantasyon, service block, toolkit, web enforcement ve kullanici standardizasyonu

---

## 1. Ilk Veeam Teshisi

Thread'in en basinda Veeam tarafinda iki farkli problem ailesi ayristirildi:

### 1.1 File Offsite / File Backup tarafi

Semptom:

- `Failed to resolve name: veeam`

Yorum:

- burada temel problem isim cozumu / DNS / host resolution olarak goruldu

### 1.2 Agent Backup tarafi

Semptom:

- `172.30.65.180:10005`
- `172.30.65.180:10006`
- timeout

Yorum:

- burada da ilk asamada port erisimi, firewall ya da dinleyen servis problemi suphe edildi

Ilk pratik strateji su sekilde kuruldu:

1. `veeam` ismini cozmek
2. `10005/10006` portlarinin dinledigini dogrulamak
3. gerekiyorsa firewall rule acmak
4. sonra test job rerun yapmak

---

## 2. IP mi, Hostname mi?

Kullanici su soruyu sordu:

- `veeam de direkt isim yerine ip girsek?`

Burada thread'in erken safhasinda su kabul edildi:

- Evet, `veeam` yerine `172.30.65.180` kullanmak en az eforlu cozumlerden biri olabilir
- ama bu sadece name resolution problemini cozer
- `10005/10006` timeout problemini tek basina cozmeyebilir

Bu asamada temel ayrim netlestirildi:

- hostname problemi farkli
- port/firewall problemi farkli

---

## 3. Repository / Managed Server / Clone Job Tartismasi

Kullanici, repository'yi IP ile yeniden eklemek, default yapmak ve clone job uzerinden test etmek gibi farkli pratik yollar denedi.

Bu surecte su olaylar konusuldu:

### 3.1 Repo'yu IP ile tekrar ekleme fikri

Degerlendirme:

- teknik olarak mumkun
- ama mevcut backup chain / job baglari bozulabilir
- "edit et" secenegi varsa onu kullanmak daha az riskli

### 3.2 Var olan job icinde repo degistirme denemesi

Kullanici su hatayla karsilasti:

- `Unable to change the backup repository. Detach the backup or start a new backup chain first.`

Yorum:

- mevcut chain baska repository'ye dogrudan tasinamiyordu
- bu da yeni chain gerektiriyordu
- bu nedenle clone job mantigi daha guvenli hale geldi

### 3.3 Clone job kullanma

Kullanici clone olusturup repository'yi orada degistirebildigini gosterdi.

Burada su strateji benimsendi:

- mevcut fail eden production job'lara dokunmadan
- clone job / test job uzerinden yeni repository ve ayarlarla dogrulama yapmak

Bu, thread'in ilerleyen safhalarinda da tekrar tekrar "en guvenli test yolu" olarak benimsendi.

---

## 4. Veeam Servisleri ve Portlarin Dogrulanmasi

Kullanici `S2Veeam` uzerinde servis ve port ciktisini paylasti.

### 4.1 Servis ciktisi

Onemli servisler calisir durumdaydi:

- `VeeamBackupSvc`
- `VeeamDeploySvc`
- `VeeamBrokerSvc`
- `VeeamTransportSvc`

Ilk yorum:

- "servisler tamamen kapali degil"
- dolayisiyla ana suphe DNS / firewall / callback portlari tarafindaydi

### 4.2 Port dinleme dogrulamasi

Kullanici su komutlarin ciktisini paylasti:

- `Get-NetTCPConnection -LocalPort 10005,10006 -State Listen`
- `netstat -ano | findstr :10005`
- `netstat -ano | findstr :10006`

Sonuc:

- `10005` listen
- `10006` listen

Yorum:

- uygulama / servis tarafi ayakta
- dis erisim yoksa kalan temel suphe firewall veya yol uzerindeki filtreleme

---

## 5. Windows Firewall Rule Acilmasi

Bu asamada `S2Veeam` uzerinde su inbound rule eklendi:

```powershell
New-NetFirewallRule -DisplayName "Veeam Agent Ports 10005-10006" -Direction Inbound -Protocol TCP -LocalPort 10005,10006 -Action Allow
```

Kullanici rule'un basariyla eklendigini paylasti.

Yorum:

- artik host uzerindeki Windows Firewall engeli buyuk olasilikla kalkmisti
- bir sonraki adim clone job'lar uzerinden test yapmakti

---

## 6. Agent Clone Job'lar ve Ilk Ilerleme

Kullanici Windows clone job'u calistirdiginda belirli bir ilerleme gordu:

- `%20` ve sonrasinda `%32` gibi ilerlemeler goruldu

Buradaki yorum:

- firewall tarafindaki degisiklik ise yariyor olabilir
- problem kokten "servis kapali" degilmis
- en azindan agent backup akisi artık ilerleyebiliyordu

Bu asamada Windows agent backup tarafi icin umit veren ilk kirilma noktasi buydu.

---

## 7. File Share / File Backup Tarafinda `veeam` Resolution Sorunu

File share job ekraninda su hata cok net goruldu:

- `Failed to resolve name: veeam`
- `Temporary failure in name resolution`

Bu noktada tartisilan cozumler:

### 7.1 Hosts kaydi eklemek

Linux tarafi icin:

```bash
echo '172.30.65.180 veeam' | sudo tee -a /etc/hosts
```

Windows tarafi icin:

- `C:\Windows\System32\drivers\etc\hosts` dosyasina kayit eklemek

### 7.2 DNS ile cozum

- `c1.local` ve `c2.local` icinde `veeam -> 172.30.65.180` A record'u

### 7.3 Sonra geri alma

Kullanici daha sonra:

- bu hosts ayarlarini nasil silebilecegini sordu
- cunku "sorunu buldum" dedigi bir noktada gecici hosts kayitlarini geri almak istedi

Silme komutu olarak:

```bash
sudo sed -i '/172\.30\.65\.180[[:space:]]\+veeam/d' /etc/hosts
```

onerildi.

---

## 8. OPNsense / Routing / Firewall Rule Karmasasi

Bir ara tartisma su noktaya geldi:

- `Bu lan rulelari etkilemiyordur degil mi`
- sonra da kullanici `OPNsense'de bir sikinti var bence` dedi

Kullanici bir dizi OPNsense screenshot'i paylasti:

- aliases
- `C1LAN`
- `C2LAN`
- `OpenVPN`
- `WAN`
- `C1DMZ`
- `C2DMZ`
- `MSP`

Bu goruntuler uzerinden yapilan teshis:

### 8.1 `S2_VEEAM` alias kapsami

- `172.30.65.180` her global alias icinde beklenen sekilde yer almiyordu

### 8.2 `VEEAM_COPY_PORTS` alias'i

- `10005` ve `10006` bu alias'ta yoktu

### 8.3 Sonuc

Thread'in o noktasindaki yorum:

- `C2LAN -> S2_VEEAM` trafiği firewall rule mantiginda dogrudan acik degildi
- `MSP`'de her yere erisim olmasi tek basina yetmiyordu
- hosttan dogrudan baslayan trafik, girdigi interface uzerindeki kurallara tabi oluyordu

### 8.4 Onerilen duzeltme mantigi

- `VEEAM_COPY_PORTS` alias'ina `10005` ve `10006` eklemek
- `C2LAN -> S2_VEEAM -> VEEAM_COPY_PORTS` pass rule
- gerekirse `C1LAN -> S2_VEEAM -> VEEAM_COPY_PORTS` pass rule

Bu asama, thread'in erken / orta safhasinda Veeam erisim probleminin host firewall disinda network path oldugunu netlestiren kritik donemlerden biriydi.

---

## 9. Agent-Based Backup / Managed by Agent / Managed by Backup Server Tartismasi

Kullanici, hocanin Site 2 icin "kesinlikle agent based" sartini koydugunu belirtti.

Burada netlestirilen kavramlar:

- `Managed by backup server` de agent-based
- `Managed by agent` de agent-based
- bunlarin hicbiri agentless degil

Ek ayrim:

- Windows ve Linux agent job'lari ayri olmali
- hatta Windows icinde client / server ayrimi yapmak da mantikli olabilir

Buradan su yapisal sonuca gidildi:

- Site 2 icin ayri Linux agent policy/job
- Site 2 icin ayri Windows agent policy/job

Ve daha sonra:

- ayni makinelerin birden fazla classic job + policy icinde yer almasi sorun yaratti
- bu da job/policy cakismasi teshisine yol acti

---

## 10. Job / Policy Cakismasi

Ekran goruntuleri uzerinden su semptomlar goruldu:

- `already processed by backup job Windows_Serversa`
- `Failed to apply backup job configuration`

Buradan cikan yorum:

- ayni hostlar birden fazla backup modeli tarafindan tutuluyordu
- bu da yeni policy'lerin apply edilirken cakismasina neden oluyordu

Benimsenen cozum:

- tek model sec
- eski classic job'lari disable et
- ayni hostu birden fazla policy/job icinde tutma

Bu konu daha sonra Veeam credential binding ve temizlik basligiyla tekrar birlestirildi.

---

## 11. `Active Full` ve `Start` Ayrimi

Kullanici:

- `Start` ve `Active Full` farkini sordu
- sonra `Active Full` baslattigini ve cok yavas oldugunu soyledi

Burada netlestirilen mantik:

- `Start`: normal run; chain yoksa zaten yeni full olur
- `Active Full`: chain olsa da olmasa da zorla yeni full baslatir

Kullanici onceden backup dosyalarini sildigini belirtince:

- `Start` da fiilen full backup gibi davranacakti
- `Active Full` ekstra gereksiz yuke sebep oluyordu

Bu konu, backup davranisinin dogru aciklanmasi acisindan thread'de net kapatildi.

---

## 12. Docker mi, Host-Based Web Server mi?

Kullanici su yeni karari verdi:

- `C2WebServer` Docker yerine dogrudan Linux web server ile calissin
- sebep:
  - backup tarafinda Docker ek karmasiklik yaratiyordu
  - snapshot/agent backup davranisi daha temiz olmaliydi

Ardindan tartisildi:

- Docker bazen izolasyon / deployment acisindan avantaj saglayabilir
- ama bu ortamda basit, tek servisli, ic web sayfasi senaryosunda host-based `nginx` daha temiz bir operasyonel secimdi

Sonuc:

- Docker devreden cikarilacak
- `nginx` host uzerinde calisacak

---

## 13. `C2WebServer` uzerinde Host-Based Nginx Kurulumu

Kullaniciya once teorik adimlar verildi:

- `nginx` kurulumu
- host site dosyasi yazimi
- `80/443` dinleme, cert path, hostname-only davranis
- Docker'in sonradan durdurulup kaldirilmasi

Ardindan kullanici canli ortamda asamalari uyguladi:

- site file yazildi
- symlink olusturuldu
- `nginx -t` gecti
- fakat servis restart hataya dustu

Bu asamada teshis:

- syntax dogruydu
- buyuk ihtimalle `80/443` portu Docker tarafindan tutuluyordu

Sonraki asamalarda:

- Docker / port cakismasi mantigi konusuldu
- nihayetinde canli duzeltme daha sonra uzaktan yapildi

---

## 14. C1 ve C2 Web Enforcement

Kullanici, web serverlarin sadece `443` hizmeti vermesi gerektigini netlestirdi:

- OPNsense uzerinde `80` portunu DMZ interface'lerinde kapattigini belirtti
- ama dogrudan web app seviyesinde de `80` hizmet verilmesin istiyordu

Bu karar iki tarafa ayrildi:

### 14.1 C1 tarafi

Kullanici GUI uzerinden kendisinin yapacagini belirtti.

Bu nedenle ona adim adim IIS GUI yonergesi verildi:

1. `C1-WebServer`a RDP ile baglan
2. IIS Manager ac
3. `Sites > Bindings`
4. `http :80` binding'lerini kaldir
5. sadece `https :443` ve dogru hostname kalsin
6. fallback/default site tenant content donmesin
7. gerekiyorsa `iisreset`

### 14.2 C2 tarafi

Bu taraf uzaktan tarafimizdan duzenlendi:

- `nginx` sadece `443` dinleyecek sekilde guncellendi
- `HTTP/80` devreden cikarildi
- hostname-only / IP-denince `404` mantigi korundu

Bu degisiklik sonradan canli olarak uygulanip dogrulandi.

---

## 15. Dokumantasyon Uzerindeki Kullanici Geri Bildirimleri

Kullanici, dokumantasyon tarafinda birkac net elestiri getirdi:

- bazi figure'lar yanlis
- bazi figure'lar yanlis yerde
- Site 1 dokumanina gore fazla gevsek / hizli gidilmisti
- screenshot istekleri dokumani desteklemiyordu
- Site 1'in baslik yapisi da referans alinmaliydi
- Site 2 teknik dokuman daha anlatili, donusum hikayesi daha belirgin olmaliydi

Bu elestiriler sonucunda su prensipler benimsendi:

- Site 1 = structural template
- Site 2 = ayni iskelet uzerinde kendi kanitlari
- screenshot = dekor degil, iddia kaniti
- value-add kisimlari ana demo disina alinacak
- Veeam en sona birakilacak

Thread boyunca `V3.1`, `V3.2`, `V3.5`, `V3.6`, `V3.7` gibi bazi calisma surumlerinden bahsedildi ve farkli duzeltme turlari yapildigi ifade edildi.

Kullanici, "kafana gore is yapma" diyerek ozellikle Veeam tarafini erken "remediation" gibi yazmanin yanlis oldugunu belirtti. Bu da dokumantasyonda daha dikkatli, daha kaynakli ilerleme gerektigini netlestirdi.

---

## 16. Demo Checklist / Runbook / Value-Add Ayrimi

Kullanici, service block demo checklist ve runbook tarafinda su net yonu verdi:

- AWS / Terraform / public site kisimlari demo kapsami disina ciksin
- `C2WebServer` value-add olarak dursun
- ana service-block icinde sadece proje gereklerine giren servisler ve testler yer alsin

Bu karar sonrasinda:

- demo runbook sadeleştirildi
- checklist sadeleştirildi
- `C2WebServer` "mevcut ama ana demo disi" olarak ele alindi

Burada bir ara `C1DFS` IP adresinin `.4` olarak guncellendigi de konusuldu.

---

## 17. Site 1 Toolkit / Service Block Dosyalarinin Incelenmesi

Kullanici daha sonra asagidaki dosyalari referans verdi:

- `service block v0.1.xlsx`
- `ServiceBlocks.pdf`
- `service block v3.1.xlsx`
- `Site1_Final_Documentation_V3.1.docx`
- `test_service-site1-v0.1`
- `service block-group6-v0.1.xlsx`

Ve su talebi iletti:

- Site 1 tarafindaki toolkit / script / config dosyalarini dikkatle incele
- gerekirse degisiklikleri yap
- sonra degisen dosyalari arkadasina gostermek icin ayri bir klasorde ver

---

## 18. Site 1 Toolkit Uzerinde Ilk Patch Turleri

Ilk incelemede su supheler olustu:

- `JumpboxUbuntu = admnin` typo olabilir
- `S2C1UbuntuClient = Administrator` Linux host icin tuhaf olabilir
- `C2DC1/C2DC2 = admindc` dikkat istemeli
- OPNsense `GuiPort = 80` beklenmedik gorunebilir
- asıl test mantigi problemi `C2LinuxClient per-user share access` icindeki tek-atim `smbclient` probe'u olabilir

### 18.1 Ilk patch denemesi

Bir ara su degisiklikler yapildi:

- `JumpboxUbuntu` -> `admin`
- `S2C1UbuntuClient` -> `admin`
- SMB timeout retry eklendi

Ancak daha sonra kullanici bir inventory screenshot'i gostererek sunu netlestirdi:

- `JumpboxUbuntu` Site 1 makinesidir
- onun kullanicisi inventory'deki deger olmalidir
- `S2C1UbuntuClient` de inventory'deki deger ile gitmelidir
- source of truth inventory listesi kullanicinin verdigi listedir

### 18.2 Sonrasinda yapilan geri alma

Bu geri bildirim uzerine:

- `JumpboxUbuntu` tekrar `admnin` yapildi
- `S2C1UbuntuClient` tekrar `Administrator` yapildi
- `C2DC1/C2DC2 = admindc` degistirilmedi
- `GuiPort = 80` alanlari degistirilmedi, cunku workbook ve Site 1 final doc da bunu destekliyordu

### 18.3 Korunan tek toolkit patch'i

Son durumda toolkit uzerinde gercekten korunan tek mantiksal degisiklik:

- `Group6.Tests.psm1` icinde `Site 2 C2LinuxClient per-user share access` testine `NT_STATUS_IO_TIMEOUT` retry mantigi eklenmesi

Bu patch'in mantigi:

- ilk `admin -> C2_Public` tree connect probe'u timeout olabiliyordu
- ama sonraki 5 alt kontrol ve create testleri bazen basarili oluyordu
- yani kalici yetki bozuklugu gibi degil, transient timeout gibi gorunuyordu

---

## 19. Review Klasoru

Arkadasa gostermek icin ayri klasor hazirlandi:

- `C:\Algonquin\Winter2026\Emerging_Tech\Project\site1_testtoolkit_review_changes_2026-03-25`

Icindeki ana dosyalar:

- `01_Config\LabConfig.psd1`
- `02_Modules\Group6.Tests.psm1`
- `README_Changes.md`

README son durumda su mantigi anlatiyordu:

- source-of-truth envantere aykiri config degisiklikleri geri cekildi
- tek savunulan gercek patch SMB retry mantigi
- web enforcement fail kalirsa artik toolkit username hatasi degil, canli ortam binding/firewall sorunu gibi ele alinmali

---

## 20. C2 LinuxClient ve SMB Share Problemi

Kullanici, Site 1 tarafindan gelen test sonucunu paylasti. Ozet:

- `Site 2 C2LinuxClient per-user share access summary` fail
- ama daha yakindan bakinca sadece ilk adim fail:
  - `admin -> C2_Public`
- hata:
  - `tree connect failed: NT_STATUS_IO_TIMEOUT`
- sonraki 5 alt test pass
- hatta sonraki create-and-visibility testlerinde:
  - `ADMIN_PUBLIC_CREATE_OK`

Buradan cikan yorum:

- bu fail kalici ACL / permission bozuklugu gibi gorunmuyor
- daha cok ilk SMB tree connect denemesinde transient timeout gibi

Bu bulgu, toolkit patch'inin savunulmasinda ana arguman oldu.

---

## 21. Canli Site 2 Test Sonuclari ve Fail Listesi

Bir noktada Group 6 test ozetinde su tablo goruldu:

- `PASS: 83`
- `FAIL: 5`
- `REVIEW: 1`

Flagged items:

- `C1 web application non-FQDN rejection`
- `C1-Client2 hostname-only company-web validation`
- `Site 2 C1UbuntuClient company-web hostname-only enforcement`
- `Site 2 C1FS server role and storage summary`
- `Site 2 C2LinuxClient per-user share access summary`
- review olarak:
  - `Site 2 C1WindowsClient interactive share workflow`

Bu asamada analiz su sekilde yapildi:

### 21.1 C1 web fail'leri

Aslinda 3 farkli fail gorunse de ortak kok neden:

- `C1` web uygulamasi hala bir path uzerinden `HTTP/FQDN` ile cevap veriyordu

### 21.2 C1FS fail'i

Yorum:

- bu dogrudan storage bozuklugu degil
- buyuk ihtimalle WinRM / management-plane baglanti sorunu

### 21.3 C2LinuxClient per-user share access

Yorum:

- ilgili diger testler pass oldugu icin bu tek basina genel tasarim bozuklugu gostermiyordu
- toolkit patch ya da transient network durumu ile iliskili olabilirdi

Bu noktada kullaniciya net bir "kalan problem listesi" cikarildi.

---

## 22. `C2LinuxClient` Domain / Local User Karmasasi

Thread'in buyuk bir kismi `C2LinuxClient` ve diger Linux hostlarda local vs domain `admin` davranişını netlestirmekle gecti.

Gorulen durumlar:

- `C2IdM1` uzerinde `admin` local user olarak gorunuyordu
- `C2FS` uzerinde `admin` bazen domain user gibi davranabiliyordu
- `C2LinuxClient` uzerinde:
  - bir asamada `admin@c2.local` ile SSH mumkun oldu
  - ama home directory ve short-name davranisi karisik ilerledi

### 22.1 `admin@c2.local` denemeleri

Bir ara:

- `ssh admin@c2.local@172.30.65.68`
- `ssh -l 'admin@c2.local' 172.30.65.70`

gibi denemeler yapildi.

Sonuclardan cikan yorum:

- bazi hostlar domain user'i kabul ediyor
- bazilarinda short-name/domain-name davranisi farkli

### 22.2 `C2LinuxClient` uzerinde final duzeltme

Bir noktada net olarak goruldu:

- prompt hala `odengiz`
- `getent passwd admin` bos
- `getent passwd 'admin@c2.local'` da bos ya da tutarsiz

Sonuc:

- bu hostta `admin` standardi duzgun oturmamis
- en temiz yol local `admin` hesabini net oturtmak

Sonraki denemelerde:

- local `admin` olusturuldu
- `/home/admin` sahibi `root:root` oldugu icin `Permission denied` alindi
- sonra:
  - `chown -R admin:admin /home/admin`
  - `chmod 700 /home/admin`

ile home dizini duzeltildi

Sonra:

- `C2LinuxClient` da local `admin` standardina oturdu

---

## 23. `mspubuntujump`, `C2IdM1`, `C2IdM2`, `C2FS`, `C2WebServer` Uzerinde Kullanici Gecisleri

Thread boyunca Linux hostlarda su kullanici gecisleri ve testleri yapildi:

- `mspadmin` -> `admin`
- `ofdengiz` -> `admin`
- `odengiz` -> `admin`

Ancak bu islem her hostta ayni sekilde ilerlemedi.

### 23.1 Canli oturumda kullaniciyi rename etme problemi

`usermod -l admin ofdengiz` gibi denemelerde:

- aktif process kullanimi
- `systemd --user`
- `sshd`
- Veeam subprocess'leri

sebebiyle hata alindi.

### 23.2 Guvenli strateji

Bu nedenle su prensip benimsendi:

- aktif kullaniciyi oturum icindeyken rename etme
- yeni `admin` hesabini olustur
- `sudo` ve SSH testini yap
- sonra eski kullaniciyi sil

### 23.3 Veeam etkisi

Ozellikle `c2idm1` gibi hostlarda:

- `veeamdeployment` surekli eski kullanici altinda subprocess aciyordu
- bu da `userdel`'i engelliyordu

Bu noktada:

- gerekirse `veeamdeployment`, `veeamservice`, `veeamtransport` durdurulup sonra eski kullanici silme stratejisi tartisildi
- ama riskli oldugu icin dikkatli davranildi

---

## 24. Site 2 Access Matrix'in Netlesmesi

Bir noktada thread sonunda guncel erisim matrisi topluca netlestirildi:

### SSH

- `mspubuntujump`
- `C2IdM1`
- `C2IdM2`
- `C2FS`
- `C2LinuxClient`
- `C2WebServer`

hepsi icin:

- `admin`
- `Cisco123!`

### RDP

- `Jump64`
- `S2Veeam`

icin:

- `.\Administrator`
- `Cisco123!`

Bu matris daha sonra Veeam credential standardizasyonunun da temeli haline geldi.

---

## 25. `S2Veeam` Administrator Lockout Problemi

Kullanici `Veeam serverin kullanici sifresini degistirdim su anda gui a baglanmiyor` dedi.

Ilk suphe:

- servislerin yeni sifre ile acilamiyor olmasi

Kullanici servis ciktisini paylasti:

- Veeam servisleri `LocalSystem` ile calisiyordu

Bu nedenle yorum:

- problem dogrudan servis account sifresi degil

Sonra:

- `VeeamBackupSvc` stopped
- `VeeamMountSvc` stopped

olarak tespit edildi

Bir sure sonra:

- `VeeamBackupSvc` yeniden calisti

Ama ardindan:

- `net use \\HOST\ADMIN$ /user:HOST\Administrator Cisco123!`

testinde:

- `System error 1909`
- `The referenced account is currently locked out`

alindi

Bu asamada:

- local `Administrator` lockout'unun acilmasi
- Veeam GUI icindeki eski credential objelerinin degistirilmesi

konulari tartisildi.

Kullanicinin vardigi pratik karar:

- server uzerinde de credential duzeltmesi gerekecek
- sonra Veeam icindeki credential binding'leri temizlenecek

---

## 26. `C2WebServer` ve `C2IdM1` Uzerinde Veeam Guest Credential Fail

Kullanici:

- `66 ve 170 makinalarinin guncel veeam credentiallari nasil olmali`
- sonra da:
- `hala bu ikisinde guest credential test fail oluyor`

dedi.

Hostlar uzaktan kontrol edildi.

Sonuc:

### `172.30.65.66` `c2idm1`

- `admin` local user
- home `/home/admin`
- owner dogru
- `sudo` calisiyor
- eski kullanicilar yok

### `172.30.65.170` `c2-webserver`

- `admin` local user
- home `/home/admin`
- owner dogru
- `sudo` calisiyor
- eski kullanicilar yok

Yorum:

- guest credential fail'in nedeni artik host uzerindeki kullanici yapisi degil
- buyuk ihtimalle Veeam icinde eski credential binding ya da cache

---

## 27. `C2WebServer` Uzerinde Veeam Servislerinin Uzaktan Baslatilmasi

Sonrasinda kullanici:

- `hayir veeam uzerinde connection refuse aliyorum ondan`

dedi.

Burada host tarafina gidilip kontrol yapildi.

Bulgu:

- `c2-webserver` uzerinde Veeam paketleri vardi
- ama servisler `inactive dead`

Sonra gerekenler yapildi:

- `veeamdeployment`
- `veeamservice`
- `veeamtransport`

baslatildi / enable edildi

Sonuc:

- servisler active
- `6162` dinliyor

Yorum:

- bu host icin `connection refused` semptomunun ana sebebi kapanmis oldu

---

## 28. Site 2 Credential Standardi ve Veeam Icin Son Onerilen Model

Thread sonlarina dogru Veeam icin su model netlestirildi:

### Windows

- `.\Administrator`
- `Cisco123!`

### Linux

- `admin`
- `Cisco123!`

Notlar:

- eski `odengiz`, `ofdengiz`, `mspadmin` credential objeleri test gecene kadar tutulabilir
- ama yeni yapida aktif olarak kullanilmamalidir

---

## 29. Site 2 Service Block Sonucunun Iyilesmesi

Sonunda kullanici yeni bir test sonucu paylasti:

- `PASS: 87`
- `FAIL: 0`
- `REVIEW: 2`

Bu andan itibaren:

- onceki blocker fail'ler kapanmis sayildi

Kalan iki review:

### 29.1 `Site 2 C2LinuxClient user identity contexts`

Yorum:

- artik hard fail degil
- toolkit ek kanit toplamış ama manuel takip tavsiye ediyor

### 29.2 `Site 2 C1WindowsClient interactive share workflow (manual)`

Yorum:

- bu dogasi geregi manual / context-specific follow-up gibi goruldu

Bu nedenle thread o noktasinda su sonuc verildi:

- teknik fail kalmadi
- sadece iki review / manual follow-up kaldi

---

## 30. Kullanici Tarafindan Sonradan Tekrar Vurgulanan Source-of-Truth Inventory

Thread'in sonlarina yakin kullanici:

- kendi elindeki inventory / machine list screenshot'ini paylasti
- `JumpboxUbuntu`'nun Site 1 makinasi oldugunu
- `S2C1UbuntuClient` gibi entry'lerde de source-of-truth inventory'nin esas alinmasi gerektigini

tekrar vurguladi.

Bu noktada:

- onceki config normalize etme denemesi net olarak hatali kabul edildi
- toolkit config bu envanter listesine gore geri duzeltildi

Ve son durumda tekrar netlestirildi:

- `JumpboxUbuntu = admnin`
- `S2C1UbuntuClient = Administrator`
- `C2DC1/C2DC2 = admindc`

Bu satirlara artik kullanicinin source-of-truth inventory'si disinda mudahale edilmemesi gerektigi kabul edildi.

---

## 31. Bu Thread Boyunca Kullanici Tarafindan Verilen Ana Yonler

Thread boyunca kullanicinin onceliklendirdigi ve defalarca teyit ettigi ana yonler:

1. Site 1 dokumani ve yapisi ciddi sekilde referans alinacak
2. Site 2 dokumani ayni seviyede ya da daha iyi olacak
3. Screenshot'lar sadece gercekten dokumani destekleyen kanitlardan secilecek
4. Veeam ekran goruntuleri en sona birakilacak
5. Value-add alanlar demo ana akistan ayrilacak
6. Teknik dokuman daha hikayeli, karar gerekceli ve evrimsel olacak
7. "Kafana gore" degil, source-of-truth inventory ve kullanici geri bildirimiyle ilerlenilecek

---

## 32. Bu Thread'in Sonundaki Durum Ozeti

Thread bittiginde buyuk resimde su noktaya gelinmis oldu:

### 32.1 Test durumu

- otomatik testlerde `FAIL = 0`
- sadece `REVIEW = 2`

### 32.2 Web durumu

- `C2WebServer` 443-only hale getirildi
- `C1` tarafinda GUI uzerinden `80` binding kapatma adimlari verildi

### 32.3 Kullanici standardi

- Site 2 Linux hostlar buyuk oranda `admin`
- Site 2 Windows hostlar `.\Administrator`

### 32.4 Veeam durumu

- network / firewall / port / resolution problemleri buyuk olcude ayristirildi
- `c2-webserver` uzerinde kapali Veeam servisleri tekrar baslatildi
- guest credential fail kalan yerlerde artik ana suphe host user degil, Veeam binding/caching tarafi

### 32.5 Toolkit durumu

- source-of-truth inventory disindaki config normalize etme denemeleri geri cekildi
- yalnizca SMB timeout retry patch'i korundu

### 32.6 Dokumantasyon durumu

- Site 1 yapisini referans alan daha ciddi bir yeniden duzenleme mantigi kabul edildi
- screenshot ve figure mantigi daha disiplinli hale getirildi

---

## 33. Sonraki Mantikli Adimlar

Bu thread'den sonra mantikli calisma sirasi su olabilir:

1. Veeam GUI icindeki credential binding'lerini yeni standarda gore son kez temizlemek
2. Kalan Veeam ekran goruntulerini en sona toplamak
3. Site 2 final documentation'i Site 1 omurgasina gore son kez guclendirmek
4. Site 2 service block dokumanini capraz iki-yonlu test mantigi icin daha da zenginlestirmek
5. Teknik dokumana "neydi, ne oldu, neden degistirdik" anlatisini eklemek

---

## 34. Kisa Son Soz

Bu thread, basit bir "tek hata - tek cozum" akisi olmadi. Asagidaki konular ic ice ilerledi:

- Veeam
- DNS
- firewall
- OPNsense
- SMB
- Linux user standardizasyonu
- web binding / HTTPS-only enforcement
- dokumantasyon kalitesi
- service block toolkit dogrulugu

En onemli sonuc:

- baslangictaki daginik fail tablosu, sonunda `FAIL = 0` seviyesine kadar getirildi
- ayni zamanda teknik dokuman ve toolkit tarafinda daha saglam bir metodoloji kabul edildi

