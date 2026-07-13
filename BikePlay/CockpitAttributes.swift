import ActivityKit
import Foundation

public struct KokpitAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var currentSpeed: Double
        var totalDistance: Double
    }

    var id = UUID()
}
