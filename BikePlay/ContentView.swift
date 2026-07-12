import SwiftUI
import MediaPlayer
import CoreLocation
import MapKit

struct ContentView: View {
    // Yazdığımız manager'ları ekrana bağlıyoruz
    @StateObject private var locationManager = LocationManager()
    @StateObject private var weatherManager = WeatherManager()
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    // Animasyon kontrolü için yeni değişkenlerimiz
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.7
    @State private var logoOpacity: Double = 0.0
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
                            Text(String(format: "%.0f K/S", locationManager.averageSpeed))
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.white.opacity(0.03))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding(.horizontal)
                    
                    Map(position: $position) {
                        UserAnnotation()
                    }
                    .frame(height: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal)
                    .mapControls {
                        MapUserLocationButton() // Kullanıcıyı merkeze alma butonu
                        MapCompass() // Pusula
                    }
                    .preferredColorScheme(.dark)
                    
                    
                    
                    Spacer()
                    
                    // ALT BÖLÜM: MÜZİK KARTI (CarPlay Tarzı)
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
    }
}

#Preview {
    ContentView()
}
