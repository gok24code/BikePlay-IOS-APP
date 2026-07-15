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
* **Veri Depolama:** SwiftData (App Group tabanlı paylaşımlı container)
* **Widget Grafikler:** Swift Charts (çizgi + alan gradyanı)
* **Tasarım Mimarisi:** MVVM / ObservableObject State Management & ScenePhase Lifecycle Tracking

---

## 🔧 Son Teknik Güncellemeler (16.07.2026)

### Sürüş Geçmişi & Widget Sistemi
* **SwiftData Entegrasyonu:** Trip model ve paylaşımlı App Group container (`ModelContainer.shared`) eklendi. Ana app sürüşü kaydettiğinde veritabanına yazılıyor; aylık döngü otomatik eski veriyi temizliyor.
* **App Group Kurulumu:** Ana app ve widget extension aynı `group.com.gok24code.bikeplay` App Group'unda çalışıyor — veritabanı paylaşımlı container köküne yerleştirildi, başlangıçtaki CoreData hataları çözüldü.
* **Çok Boyutlu Widget'lar:** 
  - 🟩 **Small:** Bugünün toplam kilometresi (dev rakam, hızlı bakış)
  - 📈 **Medium:** Son 7 günün çizgi grafiği + hafta toplamı
  - 📅 **Large:** Bu ayın günlük grafiği + toplam km + en iyi gün (Swift Charts)

### iOS 26 API Modernizasyonu
* **Canlı Etkinlikler:** ActivityKit imzaları güncelendi — `ActivityContent(state:staleDate:)` ile başlatma/güncelleme, etiketsiz `update(_:)` / `end(_:)` çağrıları.
* **Harita API:** Deprecated `MKPlacemark(coordinate:)` yerine `MKMapItem(location:address:nil)` ile yer işaretleri oluşturuluyor.
* **Türü Kontrol Zaman Aşımı:** Arama arayüzü (`searchOverlay`, `searchResultsList`, `searchResultRow`) bağımsız View fonksiyonlarına bölünerek compiler type-check timeout hatası çözüldü.

### Kod Kalitesi
* **Temizlik:** Tüm 11 dosya gereksiz emoji, `✅ FIX`, meta yorumlar ve tutarsız isimlendirmelerden arındırıldı. Production-ready, mülakat seviyesi kod.
* **Build Durumu:** iPhone 17 / iOS 26 simülatöründe **0 uyarı, 0 hata, temiz derlenme**.

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

- [x] **Trip History:** ✅ Yapıldı! Sürüş geçmişi SwiftData ile kaydediliyor, aylık sıfırlama, widget'ta gerçek veri akıyor.
- [ ] **Manuel Sürüş Kayıt Butonu:** Test kolaylığı için, rota tamamlanmadan sürüşü kaydetme seçeneği.
- [ ] **ESP32 / Arduino Donanım Entegrasyonu:** Bisikletin batarya yüzdesi, motor sıcaklığı ve tork verilerini Bluetooth (CoreBluetooth) üzerinden ekrana canlı akıtmak.
- [ ] **Takvim View Seçeneği:** Widget Large boyutunda grafiğin yanında takvim grid'i gösterme tercihini eklemek.
- [ ] **Akıllı Gece Modu:** Telefonun ışık sensörünü dinleyerek harita ve ekran parlaklığını otomatik optimize eden asistan modu.

---

## 🧑‍💻 Geliştirici

* **Göktuğ Toyguç** - Computer Engineering Student
* **GitHub:** [@gok24code](https://github.com/gok24code)
* **Web:** [my portfolio website](https://gok24code.github.io)

---

## 📅 Geçmiş

* **16.07.2026:** Trip History, SwiftData entegrasyonu, çok boyutlu widget'lar (small/medium/large), iOS 26 API modernizasyonu, kod temizliği tamamlandı.
* **14.07.2026:** Live Activities, Dynamic Island, rota tamamlama, hava durumu, ses kontrolü, arama debouncing üretildi.

---

*Bu proje, bisiklet gidonunda Xcode konsolunun "Build Success" sesini duymak ve sürüşü daha akıllı hale getirmek için geliştirilmiştir.* 🚴‍♂️💚
