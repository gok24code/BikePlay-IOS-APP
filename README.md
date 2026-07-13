# 🚴‍♂️ BikePlay - Fütüristik Elektrikli Bisiklet Sürüş Kokpiti

BikePlay, elektrikli bisiklet sürüş deneyimini premium ve fütüristik bir seviyeye taşımak için SwiftUI, CoreLocation ve ActivityKit mimarisi kullanılarak sıfırdan geliştirilmiş bağımsız bir native iOS yol bilgisayarı uygulamasıdır. 

Sürüş esnasında dikkati dağıtmayacak, karanlık mod (Dark Mode) odaklı ve neon yeşili detaylara sahip estetik, jilet gibi bir arayüz (UI) sunar.

---

## 🚀 Özellikler

* **Dinamik Neon Hız Kadranı (Speed Gauge):** GPS üzerinden m/s formatında gelen anlık hız verisini hassas şekilde KM/S cinsine çevirir. Hızlandıkça pürüzsüz bir animasyonla dolan fütüristik kavisli bir kadran yapısına sahiptir.
* **Gelişmiş Yol Bilgisayarı (Trip Computer):** Sürüş başladığı andan itibaren toplam süreyi, ortalama hızı ve anlık katedilen mesafeyi tutar. GPS sıçramalarını ve dur-kalk hatalarını engelleyen özel filtreleme algoritması içerir.
* **Anlık Hava Durumu:** Sürüş konumuna göre OpenMeteo API'sinden çekilen anlık sıcaklık ve hava koşulu ikonunu (güneşli, yağmurlu, karlı, sisli…) kokpitin üst kısmında gösterir; konum değiştikçe arka planda sessizce güncellenir.
* **Minimalist Akıllı Yer Arama & Otomatik Rota:** Sol alt köşede yer alan, parlayan neon yeşili büyüteç butonuna dokunulduğunda pürüzsüz bir yay efektiyle (`withAnimation(.spring)`) sağa doğru 280px genişleyen arama çubuğu. Apple sunucularını boğmayan **Debouncing (400ms Gecikmeli Tetikleme)** mekanizmasıyla klavye takılmalarını önler ve seçilen konuma anında kestirme yürüyüş/sürüş rotası çizer.
* **Kilit Ekranı Yol Bilgisayarı (Live Activities & Dynamic Island):** Rota oluşturulduğu an otomatik tetiklenen fütüristik siyah-neon yeşil Canlı Etkinlik widget'ı. Telefon kilitliyken bile anlık hız ve mesafe verilerini kilit ekranında ve Dynamic Island üzerinde anlık akıtır. Uygulama tamamen kapatıldığında (`ScenePhase` kontrolüyle) arkasında çöp bırakmadan kendini pürüzsüzce imha eder.
* **Otomatik Rota Tamamlanma Asistanı:** Sürüş esnasında hedefe 15 metreden fazla yaklaşıldığını algıladığı an haritadaki çizgiyi temizler, canlı etkinliği sonlandırır ve ekranda fütüristik bir monospaced bildirim (`.alert`) patlatır.
* **Liquid Glass Master Volume Slider:** Sürüş esnasında, eldiven takılıyken bile ekranın en altından rahatça kontrol edilebilen, iOS ana ses katmanına (System Volume) doğrudan hükmeden şık bir ses barı.
* **Sinematik Açılış Animasyonu:** DaVinci Resolve kilit kare (keyframe) mantığından ilham alan, uygulama ilk açıldığında ekranda parlayarak büyüyen minimal bir Splash Screen deneyimi.

---

## 🛠️ Kullanılan Teknolojiler

* **Dil:** Swift 6 (Strict Concurrency, `@MainActor` izolasyonu)
* **Hedef Platform:** iOS 26+ (Deployment Target: iOS 26.5)
* **Arayüz Frameworkü:** SwiftUI (Declarative UI)
* **Konum & GPS Motoru:** CoreLocation (with `kCLLocationAccuracyBestForNavigation`)
* **Harita & Navigasyon:** MapKit — `MKDirections`, `MKLocalSearch` (Debouncing Search Task) & modern `MKMapItem(location:address:)` API'si
* **Canlı Etkinlikler:** ActivityKit & WidgetKit (Dynamic Island & Lock Screen Support)
* **Hava Durumu:** OpenMeteo REST API (`URLSession` + async/await)
* **Ses Kontrolü:** MediaPlayer / `MPVolumeView`
* **Tasarım Mimarisi:** MVVM / ObservableObject State Management & ScenePhase Lifecycle Tracking

---

## 🔧 Son Teknik Güncellemeler

* **iOS 26 API Modernizasyonu:** Canlı Etkinlikler artık güncel ActivityKit imzalarıyla çalışıyor — `ActivityContent(state:staleDate:)` ile başlatma/güncelleme ve etiketsiz `update(_:)` / `end(_:)` çağrıları. Rota noktaları ise deprecated `MKPlacemark` yerine yeni `MKMapItem(location:address:)` API'sine taşındı.
* **Derleyici Performansı:** Arama arayüzü bağımsız alt-View fonksiyonlarına (`searchOverlay`, `searchResultsList`, `searchResultRow`) bölünerek SwiftUI'nin "type-check timeout" hatası giderildi ve build süresi kısaldı.
* **Kod Temizliği:** Tüm dosyalar gereksiz yorumlardan ve tutarsız isimlendirmelerden arındırıldı; sade, okunabilir ve bakımı kolay bir yapıya kavuşturuldu.
* **Build Durumu:** iPhone 17 / iOS 26 simülatöründe **0 uyarı, 0 hata**.

---

## 📸 Ekran Görüntüleri
|UYGULAMA ARAYÜZÜ|SPLASH SCREEN|
|---|---|
| <img src="https://raw.githubusercontent.com/gok24code/BikePlay-IOS-APP/refs/heads/main/IMG_5970.png" width = "250">| <img src="https://raw.githubusercontent.com/gok24code/BikePlay-IOS-APP/refs/heads/main/Ekran%20Resmi%202026-07-12%2006.12.34.png" width = "250">
| <img src="https://raw.githubusercontent.com/gok24code/BikePlay-IOS-APP/refs/heads/main/IMG_5969.png" width = "250">
||
| <img src="https://raw.githubusercontent.com/gok24code/BikePlay-IOS-APP/refs/heads/main/IMG_5968.png" width = "250">

---

## 🏎️ Gelecek Planları (Roadmap)

- [ ] **ESP32 / Arduino Donanım Entegrasyonu:** Bisikletin batarya yüzdesi, motor sıcaklığı ve tork verilerini Bluetooth (CoreBluetooth) üzerinden ekrana canlı akıtmak.
- [ ] **Trip History:** Geçmiş sürüş rotalarını ve istatistiklerini yerel veri tabanına (SwiftData/CoreData) kaydedip listelemek.
- [ ] **Akıllı Gece Modu:** Telefonun ışık sensörünü dinleyerek harita ve ekran parlaklığını otomatik optimize eden asistan modu.

---

## 🧑‍💻 Geliştirici

* **Göktuğ Toyguç** - Computer Engineering Student
* **GitHub:** [@gok24code](https://github.com/gok24code)
* **Web:** [my portfolio website](https://gok24code.github.io)

---
*Bu proje, bisiklet gidonunda Xcode konsolunun "Build Success" sesini duymak ve sürüşü daha akıllı hale getirmek için geliştirilmiştir.*
