import SwiftUI
import MediaPlayer
import CoreLocation
import MapKit

struct ContentView: View {
    // Yazdığımız manager'ları ekrana bağlıyoruz
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
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
                
                // Arka planı koyu yapıyoruz (Gidonda gece/gündüz rahat okunsun)
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 15) {
                    //speed-o-meter
                    ZStack {
                        
                        Circle()
                            .trim(from: 0.15, to: 0.85) // Alttan biraz açık yarım daire formatı
                            .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.init(degrees: 90)) // Kadranı yukarı doğru çevirir
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
                    
                    
                    //weather
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
                    
                    
                    HStack(alignment: .center) {
                        // 2. MESAFE SÜTUNU
                        VStack(spacing: 4) {
                            Text("MESAFE")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                            // Metreyi kilometreye çevirip virgülden sonra tek hane gösteriyoruz (Örn: 1.2 KM)
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
                    
                    
                    //MAP------------------------
                    ZStack(alignment: .topLeading){
                        MapReader { reader in
                            Map(position: $position) {
                                UserAnnotation{
                                    ZStack{
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
                                
                                if !locationManager.remainingRouteCoordinates.isEmpty{
                                    MapPolyline(coordinates: locationManager.remainingRouteCoordinates)
                                        .stroke(LinearGradient(colors:[Color.green,Color.cyan],startPoint: .leading, endPoint: .trailing), style: StrokeStyle(
                                            lineWidth: 7,
                                            lineCap: .round,
                                            lineJoin: .round,
                                            
                                        ))
                                    MapPolyline(coordinates:   locationManager.remainingRouteCoordinates)
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
                                // Ekranda tam olarak dokunduğun piksel noktasını (screenPoint)
                                // Harita üzerindeki gerçek dünya koordinatına (enlem/boylam) hatasız çevirir
                                if let coordinate = reader.convert(screenPoint, from: .local) {
                                    Task {
                                        await locationManager.calculateRoute(to: coordinate)
                                    }
                                }
                            }
                        }
                        
                        //Location Search Bar.
                        VStyleSearchOverlay()
                    }
                    
                    Spacer()
                    
                    VStack() {
                        HStack {
                            Image(systemName: "speaker.wave.1.fill")
                                .foregroundColor(.green)
                            
                            VolumeSliderView()
                                .frame(height: 30) // Ses barının yüksekliği
                            
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
            }else {
                
                // --- AMBLEMATİK AÇILIŞ ANİMASYONU ---
                Color.black // Arka plan tamamen simsiyah
                    .ignoresSafeArea()
                
                VStack(spacing: 15) {
                    // Fütüristik Neon Yeşil Bisiklet Logosu
                    Image(systemName: "bicycle")
                        .font(.system(size: 85, weight: .ultraLight))
                        .foregroundColor(.green)
                        .shadow(color: .green.opacity(0.8), radius: 20)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                    
                    // Uygulama İsmi
                    Text("BIKEPLAY")
                        .font(.system(size: 28, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(6) // Harflerin arasını açarak premium hava katıyoruz
                        .opacity(logoOpacity)
                }
                .onAppear {
                    // 1. Aşama: Logo ekranda pürüzsüzce büyüyerek belirir
                    withAnimation(.easeOut(duration: 1.2)) {
                        self.logoScale = 1.0
                        self.logoOpacity = 1.0
                    }
                    
                    // 2. Aşama: 2.5 saniye sonra ana ekrana pürüzsüz geçiş yapar
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.isActive = true
                        }
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear{
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
                    // Tamam butonuna basınca durumu sıfırlıyoruz ki bir sonraki rotada yine çalışsın
                    locationManager.isRouteCompleted = false
                }
            )
        }
    }
    
    //Search bar Structure
    @ViewBuilder
    private func VStyleSearchOverlay() -> some View {
        VStack(spacing: 8) {
            // 1. ÜSTTEKİ SONUÇ LİSTESİ (Pürüzsüz geçişli hale getirildi)
            if isSearchExpanded && !locationManager.searchResults.isEmpty && !searchQuery.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(locationManager.searchResults, id: \.self) { item in
                            Button(action: {
                                let coord = item.placemark.coordinate
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
            
            // 2. ALTTAKİ ARAMA KUTUSU (Klavye takılması engellenen optimize tasarım)
            HStack {
                if isSearchExpanded {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.green)
                        .transition(.opacity)
                    
                    TextField("Search...", text: $searchQuery)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                        .transition(.opacity)
                        .onChange(of: searchQuery) { newValue in
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
        .padding([.leading], 24).padding([.top],10  )
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: locationManager.searchResults)
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: isSearchExpanded)
    }
}

#Preview {
    ContentView()
}
