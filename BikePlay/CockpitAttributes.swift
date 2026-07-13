import ActivityKit
import Foundation

public struct KokpitAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Kilit ekranında sürekli güncellenecek anlık veriler
        var currentSpeed: Double
        var totalDistance: Double
    }

    // Sabit veriler (Etkinlik boyunca değişmeyen)
    var id = UUID()
}
