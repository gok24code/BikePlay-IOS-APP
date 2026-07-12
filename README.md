# 🚴‍♂️ BikePlay - Fütüristik Elektrikli Bisiklet Sürüş Kokpiti

BikePlay, elektrikli bisiklet sürüş deneyimini premium ve fütüristik bir seviyeye taşımak için SwiftUI ve CoreLocation mimarisi kullanılarak sıfırdan geliştirilmiş native bir iOS yol bilgisayarı uygulamasıdır. 

Sürüş esnasında dikkati dağıtmayacak, karanlık mod (Dark Mode) odaklı ve neon yeşili detaylara sahip estetik bir arayüz (UI) sunar.

---

## 🚀 Özellikler

* **Dinamik Neon Hız Kadranı (Speed Gauge):** GPS üzerinden m/s formatında gelen anlık hız verisini hassas şekilde KM/S cinsine çevirir. Hızlandıkça pürüzsüz bir animasyonla dolan fütüristik kavisli bir kadran yapısına sahiptir.
* **Gelişmiş Yol Bilgisayarı (Trip Computer):** Sürüş başladığı andan itibaren toplam süreyi, ortalama hızı ve anlık katedilen mesafeyi tutar. GPS sıçramalarını ve dur-kalk hatalarını engelleyen özel filtreleme algoritması içerir.
* **Canlı Karanlık Harita Entegrasyonu:** MapKit altyapısı kullanılarak entegre edilen canlı harita, uygulamanın genel estetiğine uyum sağlaması için gece modunda çalışır ve anlık konumu pürüzsüz takip eder.
* **Liquid Glass Master Volume Slider:** Sürüş esnasında, eldiven takılıyken bile ekranın en altından rahatça kontrol edilebilen, iOS ana ses katmanına (System Volume) doğrudan hükmeden şık bir ses barı.
* **Sinematik Açılış Animasyonu:** DaVinci Resolve kilit kare (keyframe) mantığından ilham alan, uygulama ilk açıldığında ekranda parlayarak büyüyen minimal bir Splash Screen deneyimi.

---

## 🛠️ Kullanılan Teknolojiler

* **Dil:** Swift
* **Arayüz Frameworkü:** SwiftUI (Declarative UI)
* **Konum & GPS Motoru:** CoreLocation (with `kCLLocationAccuracyBestForNavigation`)
* **Harita:** MapKit
* **Tasarım Mimarisi:** MVVM / ObservableObject State Management

---

## 📸 Ekran Görüntüleri
 <img src="[https://via.placeholder.com/300x600.png?text=Sürüş+Ekranı+Görseli](https://github.com/gok24code/BikePlay-IOS-APP/blob/main/Ekran%20Resmi%202026-07-12%2006.12.22.png)"> | <img src="[https://via.placeholder.com/300x600.png?text=Splash+Screen+Görseli](https://github.com/gok24code/BikePlay-IOS-APP/blob/main/Ekran%20Resmi%202026-07-12%2006.12.34.png)">

> *Not: Kendi ekran görüntülerini `Assets` klasörüne ekledikten sonra yukarıdaki placeholder linklerini yerel dosya yollarıyla güncelleyebilirsin.*

---

## 🏎️ Gelecek Planları (Roadmap)

- [ ] **ESP32 / Arduino Donanım Entegrasyonu:** Bisikletin batarya yüzdesi, motor sıcaklığı ve tork verilerini Bluetooth (CoreBluetooth) üzerinden ekrana canlı akıtmak.
- [ ] **Trip History:** Geçmiş sürüş rotalarını ve istatistiklerini yerel veri tabanına (SwiftData/CoreData) kaydedip listelemek.
- [ ] **Akıllı Gece Modu:** Telefonun ışık sensörünü dinleyerek harita ve ekran parlaklığını otomatik optimize eden asistan modu.

---

## 🧑‍💻 Geliştirici

* **Göktuğ Toyguç** - Computer Engineering Student
* **GitHub:** [@gok24code](https://github.com/gok24code)

---
*Bu proje, bisiklet gidonunda Xcode konsolunun "Build Success" sesini duymak ve sürüşü daha akıllı hale getirmek için geliştirilmiştir.*
