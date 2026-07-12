//
//  LocationManager.swift
//  BikePlay
//
//  Created by Göktuğ Toyguc on 12.07.2026.
//
import Foundation
import CoreLocation
internal import Combine

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
    
    // Telefonun konumu veya hızı her değiştiğinde bu fonksiyon otomatik tetiklenir
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentCoordinate = location.coordinate
        
        // Telefonun bize m/s (metre/saniye) olarak verdiği hızı km/s formatına çeviriyoruz (3.6 ile çarparak)
        if location.speed > 0 {
            self.speed = location.speed * 3.6
            // Ortalama hız hesaplaması için anlık hızı listeye ekliyoruz
            self.speedsList.append(self.speed)
        } else {
            self.speed = 0.0
        }
        
        // --- Mesafe Hesaplama Mantığı ---
        if let last = lastLocation {
            let distanceIncrement = location.distance(from: last)
            
            // GPS sıçramalarını ve dur kalklardaki hatalı mesafe artışlarını engellemek için filtre
            if distanceIncrement > 0.5 && location.speed > 0.1 {
                self.totalDistance += distanceIncrement
            }
        }
        lastLocation = location
        // ---------------------------------
    }
    
    // Kaydedilen hızların ortalamasını alan fonksiyon
    private func calculateAverageSpeed() {
        guard !speedsList.isEmpty else { return }
        let sum = speedsList.reduce(0, +)
        self.averageSpeed = sum / Double(speedsList.count)
    }
    
    // Süreyi arayüzde "00:00" formatında göstermek için yardımcı fonksiyon
    func formattedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
