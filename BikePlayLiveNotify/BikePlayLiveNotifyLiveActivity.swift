import ActivityKit
import WidgetKit
import SwiftUI
 
struct BikePlayLiveNotifyLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: KokpitAttributes.self) { context in
            // --- 1. KLASİK KİLİT EKRANI PANELİ ---
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "bicycle")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                        Text("Bike Play")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.green)
                    }
                    Text(String(format: "%.2f km", context.state.totalDistance / 1000.0))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Current Speed")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.gray)
                    // ✅ FIX: '+' operator deprecated → Use string interpolation (iOS 26+)
                    Text("\(String(format: "%.1f", context.state.currentSpeed)) km/h")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.black)
            
        } dynamicIsland: { context in
            // --- 2. DYNAMIC ISLAND TASARIMI (iPhone 14 Pro ve üstü) ---
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(String(format: "%.1f km", context.state.totalDistance / 1000.0), systemImage: "flag.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 13, weight: .bold))
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Label(String(format: "%.1f km/s", context.state.currentSpeed), systemImage: "speedometer")
                        .foregroundColor(.green)
                        .font(.system(size: 13, weight: .bold))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bike Play Current Trip")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
            } compactLeading: {
                Image(systemName: "bicycle").foregroundColor(.green)
            } compactTrailing: {
                Text(String(format: "%.0f", context.state.currentSpeed)).foregroundColor(.green).bold()
            } minimal: {
                Image(systemName: "bicycle").foregroundColor(.green)
            }
        }
    }
}
