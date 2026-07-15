//
//  LocationManager.swift
//  BikePlay
//
//  Created by Göktuğ Toyguc on 12.07.2026.
//

import Foundation
import CoreLocation
internal import Combine
@preconcurrency import MapKit
import ActivityKit
import SwiftData

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var speed: Double = 0.0
    @Published var currentCoordinate: CLLocationCoordinate2D?

    @Published var totalDistance: Double = 0.0   // metre
    @Published var elapsedTime: TimeInterval = 0  // saniye
    @Published var averageSpeed: Double = 0.0     // km/h
    @Published var route: MKRoute?

    @Published var remainingRouteCoordinates: [CLLocationCoordinate2D] = []
    @Published var searchResults: [MKMapItem] = []
    @Published var isRouteCompleted: Bool = false

    private var currentActivity: Activity<KokpitAttributes>?
    private var lastLocation: CLLocation?
    private var timer: Timer?

    private var lastRouteUpdateTime = Date()
    private let routeUpdateThrottle: TimeInterval = 0.5

    // Trip kaydetme closure'ü — ContentView'den set edilir
    var onTripComplete: ((Date, Double, TimeInterval, Double) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        startTripTimer()
    }

    private func startTripTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.elapsedTime += 1
                self.calculateAverageSpeed()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        if currentCoordinate == nil {
            currentCoordinate = location.coordinate
        }

        guard let oldCoord = currentCoordinate else { return }

        // GPS gürültüsünü ele: rota aktifken 3 metrenin altındaki sıçramaları hareket sayma
        let oldLocation = CLLocation(latitude: oldCoord.latitude, longitude: oldCoord.longitude)
        let distanceMoved = location.distance(from: oldLocation)

        let isNoise = distanceMoved < 3.0 && !remainingRouteCoordinates.isEmpty
        if isNoise {
            updateSpeedAndDistance(from: location)
            return
        }

        currentCoordinate = location.coordinate
        updateSpeedAndDistance(from: location)

        if route != nil {
            updateRemainingRouteThrottled()
        }

        updateLiveActivityIfNeeded()
        checkRouteCompletion(from: location)
    }

    private func updateSpeedAndDistance(from location: CLLocation) {
        if location.speed >= 0 {
            self.speed = location.speed * 3.6
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
    }

    private func calculateAverageSpeed() {
        guard elapsedTime > 0, totalDistance > 0 else { return }

        let totalDistanceKM = totalDistance / 1000.0
        let totalHours = elapsedTime / 3600.0

        self.averageSpeed = totalDistanceKM / totalHours
    }

    private func updateRemainingRouteThrottled() {
        let now = Date()
        guard now.timeIntervalSince(lastRouteUpdateTime) >= routeUpdateThrottle else {
            return
        }
        lastRouteUpdateTime = now
        updateRemainingRoute()
    }

    private func updateRemainingRoute() {
        guard let userCoord = currentCoordinate, let fullRoute = route else { return }

        // Polyline taraması ana thread'i kilitlememesi için arka planda yapılır
        DispatchQueue.global(qos: .userInteractive).async { [weak self] in
            guard let self = self else { return }

            let pointCount = fullRoute.polyline.pointCount
            var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
            fullRoute.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

            var closestIndex = 0
            var shortestDistance: CLLocationDistance = .infinity
            let userLocation = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)

            for index in 0..<pointCount {
                let routeLocation = CLLocation(latitude: coords[index].latitude, longitude: coords[index].longitude)
                let distance = userLocation.distance(from: routeLocation)

                if distance < shortestDistance {
                    shortestDistance = distance
                    closestIndex = index
                }

                if distance < 5.0 {
                    break
                }
            }

            let remaining = Array(coords[closestIndex...])

            DispatchQueue.main.async {
                self.remainingRouteCoordinates = remaining
            }
        }
    }

    private func updateLiveActivityIfNeeded() {
        guard let activity = currentActivity else { return }

        let updatedState = KokpitAttributes.ContentState(
            currentSpeed: self.speed,
            totalDistance: self.totalDistance
        )

        Task {
            await activity.update(ActivityContent(state: updatedState, staleDate: nil))
        }
    }

    private func checkRouteCompletion(from location: CLLocation) {
        guard let route = self.route, !isRouteCompleted else { return }

        let destinationLocation = CLLocation(
            latitude: route.polyline.coordinate.latitude,
            longitude: route.polyline.coordinate.longitude
        )
        let distanceToDestination = location.distance(from: destinationLocation)

        // Hedefe 15 metre kalınca rotayı tamamlanmış say
        if distanceToDestination < 15.0 {
            self.isRouteCompleted = true
            self.remainingRouteCoordinates = []
            self.route = nil
            self.endLiveActivity()

            // Trip'i kaydet
            onTripComplete?(Date(), totalDistance, elapsedTime, averageSpeed)
        }
    }

    func formattedTime() -> String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    // MKMapItem(placemark:) iOS 26'da deprecated; konumdan modern MKMapItem üretir
    private static func makeMapItem(from coordinate: CLLocationCoordinate2D) -> MKMapItem {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return MKMapItem(location: location, address: nil)
    }

    @MainActor
    func calculateRoute(to destination: CLLocationCoordinate2D) async {
        guard let userCoordinate = currentCoordinate else { return }

        let request = MKDirections.Request()
        request.source = Self.makeMapItem(from: userCoordinate)
        request.destination = Self.makeMapItem(from: destination)
        request.requestsAlternateRoutes = false
        request.transportType = .walking

        let directions = MKDirections(request: request)
        do {
            let response = try await directions.calculate()
            if let fastestRoute = response.routes.first {
                self.route = fastestRoute

                let pointCount = fastestRoute.polyline.pointCount
                var coords = [CLLocationCoordinate2D](repeating: CLLocationCoordinate2D(), count: pointCount)
                fastestRoute.polyline.getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

                self.remainingRouteCoordinates = coords
                self.startLiveActivity()
            }
        } catch {
            print("Rota Hesaplama Hatası: \(error.localizedDescription)")
        }
    }

    func searchPlaces(query: String) {
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
                Task { @MainActor in
                    self.searchResults = response.mapItems
                }
            }
        }
    }

    private func startLiveActivity() {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        if currentActivity != nil { return }

        let attributes = KokpitAttributes()
        let initialState = KokpitAttributes.ContentState(
            currentSpeed: self.speed,
            totalDistance: self.totalDistance
        )

        do {
            self.currentActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: initialState, staleDate: nil),
                pushType: nil
            )
        } catch {
            print("Live Activity Başlatma Hatası: \(error.localizedDescription)")
        }
    }

    func endLiveActivity() {
        guard let activity = currentActivity else { return }

        Task {
            await activity.end(
                ActivityContent(state: KokpitAttributes.ContentState(currentSpeed: 0, totalDistance: totalDistance), staleDate: nil),
                dismissalPolicy: .immediate
            )
            self.currentActivity = nil
        }
    }

    deinit {
        timer?.invalidate()
    }
}
