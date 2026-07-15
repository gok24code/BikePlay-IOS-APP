import SwiftUI
import MediaPlayer
import CoreLocation
import MapKit
import SwiftData
import WidgetKit

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
    @Environment(\.modelContext) private var modelContext
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var searchQuery: String = ""
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
    @State private var searchTask: Task<Void, Never>? = nil
    @State private var isSearchExpanded: Bool = false

    var body: some View {
        ZStack {
            if isActive {
                Color.black.ignoresSafeArea()

                VStack(spacing: 15) {
                    // Hız göstergesi
                    ZStack {
                        Circle()
                            .trim(from: 0.15, to: 0.85)
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.init(degrees: 90))
                            .frame(width: 220, height: 220)

                        Circle()
                            .trim(from: 0.15, to: 0.15 + (0.70 * CGFloat(min(locationManager.speed, 60.0) / 60.0)))
                            .stroke(
                                LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .top, endPoint: .bottom),
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .rotationEffect(.init(degrees: 90))
                            .frame(width: 220, height: 220)
                            .shadow(color: .green.opacity(0.6), radius: 8, x: 0, y: 0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: locationManager.speed)
                        VStack(spacing: 0) {
                            Text(String(format: "%.0f", locationManager.speed))
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.4), radius: 5)

                            Text("KM/S")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.top, -5)
                        }
                    }
                    .frame(width: 240, height: 240)

                    // Hava durumu
                    HStack {
                        HStack {
                            Image(systemName: weatherManager.conditionIcon)
                                .foregroundColor(.orange)
                            Text(weatherManager.temperature)
                                .font(.title2)
                                .bold()
                        }
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal)

                    // Trip istatistikleri
                    HStack(alignment: .center) {
                        VStack(spacing: 4) {
                            Text("MESAFE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            Text(String(format: "%.1f KM", locationManager.totalDistance / 1000.0))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.green)
                                .shadow(color: .green.opacity(0.3), radius: 4)
                        }

                        Spacer()

                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 1, height: 30)

                        Spacer()

                        VStack(spacing: 4) {
                            Text("ORT. HIZ")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            Text(String(format: "%.0f KM/S", locationManager.averageSpeed))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)

                    // Harita
                    ZStack(alignment: .topLeading) {
                        MapReader { reader in
                            Map(position: $position) {
                                UserAnnotation {
                                    ZStack {
                                        Circle().fill(Color.green.opacity(0.2)).frame(width: 40, height: 40)
                                        Circle().stroke(Color.green, lineWidth: 2)
                                            .frame(width: 26, height: 26)
                                        Circle()
                                            .fill(Color.black)
                                            .frame(width: 22, height: 22)
                                        Image(systemName: "bicycle")
                                            .font(Font.system(size: 12, weight: .bold, design: .rounded))
                                            .foregroundColor(Color.green)
                                    }
                                }

                                if !locationManager.remainingRouteCoordinates.isEmpty {
                                    MapPolyline(coordinates: locationManager.remainingRouteCoordinates)
                                        .stroke(LinearGradient(colors: [Color.green, Color.cyan], startPoint: .leading, endPoint: .trailing), style: StrokeStyle(
                                            lineWidth: 7,
                                            lineCap: .round,
                                            lineJoin: .round
                                        ))
                                    MapPolyline(coordinates: locationManager.remainingRouteCoordinates)
                                        .stroke(Color.green.opacity(0.3), lineWidth: 12)
                                }
                            }
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .padding(.horizontal)
                            .mapControls {
                                MapUserLocationButton()
                                MapCompass()
                            }
                            .preferredColorScheme(.dark)
                            .onTapGesture { screenPoint in
                                if let coordinate = reader.convert(screenPoint, from: .local) {
                                    Task {
                                        await locationManager.calculateRoute(to: coordinate)
                                    }
                                }
                            }
                        }

                        searchOverlay()
                    }

                    Spacer()

                    // Ses kontrolü
                    VStack {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                                .foregroundColor(.green)

                            VolumeSliderView()
                                .frame(height: 30)

                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .cornerRadius(20)
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .onChange(of: locationManager.currentCoordinate?.latitude) { oldValue, newValue in
                    if let coord = locationManager.currentCoordinate {
                        Task {
                            await weatherManager.fetchWeather(for: coord)
                        }
                    }
                }
            } else {
                // Açılış animasyonu
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: 15) {
                    Image(systemName: "bicycle")
                        .font(.system(size: 85, weight: .ultraLight))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.8), radius: 20)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)

                    Text("BIKEPLAY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(6)
                        .opacity(logoOpacity)
                }
                .onAppear {
                    withAnimation(.easeOut(duration: 1.2)) {
                        self.logoScale = 1.0
                        self.logoOpacity = 1.0
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.isActive = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .alert(isPresented: $locationManager.isRouteCompleted) {
            Alert(
                title: Text("ROUTE COMPLETED")
                    .font(.system(.headline, design: .monospaced)),
                message: Text("See you in other routes next time!"),
                dismissButton: .default(Text("OK")) {
                    locationManager.isRouteCompleted = false
                }
            )
        }
        .onAppear {
            purgeOldMonthTrips()
            locationManager.onTripComplete = { date, distance, duration, avgSpeed in
                let trip = Trip(date: date, distanceMeters: distance, durationSeconds: duration, averageSpeedKmH: avgSpeed)
                modelContext.insert(trip)
                try? modelContext.save()
                WidgetCenter.shared.reloadAllTimelines()
            }
        }
    }

    // Yeni ay başladığında önceki ayın sürüşlerini temizle (aylık sıfırlama)
    private func purgeOldMonthTrips() {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        guard let trips = try? modelContext.fetch(FetchDescriptor<Trip>()) else { return }
        var didChange = false
        for trip in trips {
            let comps = calendar.dateComponents([.year, .month], from: trip.date)
            if comps.year != year || comps.month != month {
                modelContext.delete(trip)
                didChange = true
            }
        }
        if didChange {
            try? modelContext.save()
            WidgetCenter.shared.reloadAllTimelines()
        }
    }

    @ViewBuilder
    private func searchOverlay() -> some View {
        VStack(spacing: 8) {
            if isSearchExpanded && !locationManager.searchResults.isEmpty && !searchQuery.isEmpty {
                searchResultsList()
            }

            HStack {
                if isSearchExpanded {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.green)
                        .transition(.opacity)

                    TextField("Search...", text: $searchQuery)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .transition(.opacity)
                        .onChange(of: searchQuery) { _, newValue in
                            searchTask?.cancel()
                            searchTask = Task {
                                try? await Task.sleep(nanoseconds: 400_000_000)
                                if !Task.isCancelled {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        locationManager.searchPlaces(query: newValue)
                                    }
                                }
                            }
                        }

                    Button(action: {
                        searchQuery = ""
                        locationManager.searchResults = []
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isSearchExpanded = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .transition(.scale)
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            isSearchExpanded = true
                        }
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.green)
                            .padding(12)
                    }
                    .transition(.scale)
                }
            }
            .padding(isSearchExpanded ? 12 : 0)
            .background(Color.black.opacity(0.8))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.green.opacity(0.5), lineWidth: 1)
            )
            .frame(maxWidth: isSearchExpanded ? 280 : 50, alignment: .leading)
        }
        .padding(.leading, 24)
        .padding(.top, 10)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: locationManager.searchResults)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSearchExpanded)
    }

    @ViewBuilder
    private func searchResultsList() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(locationManager.searchResults, id: \.self) { item in
                    searchResultRow(for: item)
                    Divider().background(Color.gray.opacity(0.3))
                }
            }
            .background(Color.black.opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal, 0)
        }
        .frame(maxHeight: 180)
        .frame(width: 280, alignment: .leading)
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
    }

    @ViewBuilder
    private func searchResultRow(for item: MKMapItem) -> some View {
        Button(action: {
            let coord = item.location.coordinate
            Task {
                await locationManager.calculateRoute(to: coord)
            }
            searchQuery = ""
            locationManager.searchResults = []
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isSearchExpanded = false
            }
        }) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name ?? "Bilinmeyen Yer")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
        }
    }
}

#Preview {
    ContentView()
}
