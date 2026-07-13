//
//  LocationManager.swift
//  BikePlay
//
//  Created by Göktuğ Toyguc on 12.07.2026.
//
import Foundation
import CoreLocation
internal import Combine
import MapKit
import ActivityKit
// Ekranın bu sınıfı canlı dinlemesi için ObservableObject yapıyoruz
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    
    // Ekranda canlı değişecek hız ve konum değişkenleri
    @Published var speed: Double = 0.0
    @Published var currentCoordinate: CLLocationCoordinate2D?
    
    // --- Trip Computer (Yol Bilgisayarı) Değişkenleri ---
    @Published var totalDistance: Double = 0.0  // Metre cinsinden katedilen mesafe
    @Published var elapsedTime: TimeInterval = 0 // Saniye cinsinden geçen süre
    @Published var averageSpeed: Double = 0.0   // KM/S cinsinden ortalama hız
    @Published var route: MKRoute? = nil
    
    @Published var remainingRouteCoordinates: [CLLocationCoordinate2D] = []
    
    @Published var searchResults: [MKMapItem] = []
    @Published var isRouteCompleted: Bool = false
    var currentActivity: Activity<KokpitAttributes>? = nil
    private var lastLocation: CLLocation?
    private var timer: Timer?
    private var speedsList: [Double] = []
    // ---------------------------------------------------
    
    override init() {
        super.init()
        manager.delegate = self
        // Navigasyon modu: En yüksek GPS hassasiyetini ayarlar
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestWhenInUseAuthorization() // Kullanıcıdan konum izni ister
        manager.startUpdatingLocation() // Canlı konum takibini başlatır
        
        startTripTimer() // Süre sayacını başlatıyoruz
    }
    
    // Yol bilgisayarı için zamanlayıcıyı başlatan fonksiyon
    private func startTripTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.elapsedTime += 1
            self.calculateAverageSpeed()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        if let oldLocation = currentCoordinate {
            let loc1 = CLLocation(latitude: oldLocation.latitude, longitude: oldLocation.longitude)
            let distanceMoved = location.distance(from: loc1)
            
            if distanceMoved < 3.0 && !remainingRouteCoordinates.isEmpty {
                currentCoordinate = location.coordinate
                if location.speed > 0 {
                    self.speed = location.speed * 3.6
                    self.speedsList.append(self.speed)
                } else {
                    self.speed = 0.0
                }
                if let last = lastLocation {
                    let distanceIncrement = location.distance(from: last)
                    if distanceIncrement > 0.5 && location.speed > 0.1 {
                        self.totalDistance += distanceIncrement
                    }
                }
                lastLocation = location
                return
            }
        }
        
        currentCoordinate = location.coordinate
        
        if location.speed > 0 {
            self.speed = location.speed * 3.6
            self.speedsList.append(self.speed)
        } else {
            self.speed = 0.0
        }
        
        if let last = lastLocation {
            let distanceIncrement = location.distance(from: last)
            if distanceIncrement > 0.5 && location.speed > 0.1 {
                self.totalDistance += distanceIncrement
            }
        }
        lastLocation = location
        
        if route != nil {
            updateRemainingRoute()
        }
        
        if let activity = currentActivity {
                 let updatedState = KokpitAttributes.ContentState(currentSpeed: self.speed, totalDistance: self.totalDistance)
                 Task {
                     await activity.update(using: updatedState)
                 }
             }
        
        if let route = self.route, !isRouteCompleted {
            let destinationLocation = CLLocation(latitude: route.polyline.coordinate.latitude, longitude: route.polyline.coordinate.longitude)
            let distanceToDestination = location.distance(from: destinationLocation)
            if distanceToDestination < 15.0 {
                DispatchQueue.main.async {
                    self.isRouteCompleted = true
                    
                    self.remainingRouteCoordinates = []
                    self.route = nil
                    self.endLiveActivity()
                }
            }
        }
        
    }
    // Kaydedilen hızların ortalamasını alan fonksiyon
    private func calculateAverageSpeed() {
        guard elapsedTime > 0 , totalDistance > 0
        else {return}
        
        let totalDistanceKM = totalDistance / 1000
        let totalHours = elapsedTime / 3600
        
        self.averageSpeed = totalDistanceKM / totalHours
    }
    
    // Süreyi arayüzde "00:00" formatında göstermek için yardımcı fonksiyon
    func formattedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    @MainActor
    func calculateRoute(to destination: CLLocationCoordinate2D) async {
        guard let usercoordinate = currentCoordinate else { return }
        
        let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: usercoordinate))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
            request.requestsAlternateRoutes = false // Çoklu rota yerine en hızlı tek rotaya odaklanıp performansı koruyoruz
            request.transportType = .walking
            
        
        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let fastestRoute = response.routes.first {
                self.route = fastestRoute
                
                // PERFORMANS NOKTASI: İlk çizimde döngüye girmeden tüm koordinatları direkt basıyoruz
                let pointCount = fastestRoute.polyline.pointCount
                var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
                fastestRoute.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
                
                self.remainingRouteCoordinates = coords
                self.startLiveActivity()
            }
        } catch {
            print("Modern Rota Motoru Hatası: \(error.localizedDescription)")
        }
    }
    func updateRemainingRoute() {
        guard let userCoord = currentCoordinate, let fullRoute = route else { return }
        
        // Ağır matematiksel döngüyü ana arayüzü (Main Thread) kilitlemesin diye arka plan kanalına taşıyoruz
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }
            
            let pointCount = fullRoute.polyline.pointCount
            var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            fullRoute.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
            
            var closestIndex = 0
            var shortestDistance: CLLocationDistance = .infinity
            
            let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            
            // Performans optimizasyonu: Her adımda yeni CLLocation üretmek yerine
            // doğrudan en yakın noktayı bulup döngüyü hafifletiyoruz
            for index in 0..<pointCount {
                let coord = coords[index]
                let routeLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
                let distance = userLocation.distance(from: routeLocation)
                
                if distance < shortestDistance {
                    shortestDistance = distance
                    closestIndex = index
                }
                
                // Eğer konum rotaya 5 metreden daha yakınsa döngüyü erken bitir (Early Exit)
                // Bu sayede binlerce noktayı gereksiz yere dönmesini engelliyoruz
                if distance < 5.0 {
                    closestIndex = index
                    break
                }
            }
            
            // Filtrelenmiş yeni rotayı arayüze paslarken tekrar ana kanala güvenli şekilde dönüyoruz
            let remaining = Array(coords[closestIndex...])
            DispatchQueue.main.async {
                self.remainingRouteCoordinates = remaining
            }
        }
    }
    
    func searchPlaces(query: String){
        guard !query.isEmpty else {
            self.searchResults = []
            return
        }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region = self.currentCoordinate {
            request.region = MKCoordinateRegion(
                center: region,
                latitudinalMeters: 50000,
                longitudinalMeters: 50000
            )
        }

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            guard let self = self else { return }
            if let response = response {
                DispatchQueue.main.async {
                    self.searchResults = response.mapItems
                }
            }
        }
    }
    func startLiveActivity() {
        // Kullanıcının ayarlardan Canlı Etkinlik izni verip vermediğini kontrol ediyoruz
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        // Eğer halihazırda açık bir aktivite varsa yenisini açmadan çıkıyoruz
        if currentActivity != nil { return }

        let attributes = KokpitAttributes()
        let initialState = KokpitAttributes.ContentState(currentSpeed: self.speed, totalDistance: self.totalDistance)

        do {
            self.currentActivity = try Activity.request(attributes: attributes, contentState: initialState)
        } catch {
            print("Live Activity hatası: \(error.localizedDescription)")
        }
    }
    func endLiveActivity() {
        Task {
            await currentActivity?.end(dismissalPolicy: .immediate)
            self.currentActivity = nil
        }
    }
}
