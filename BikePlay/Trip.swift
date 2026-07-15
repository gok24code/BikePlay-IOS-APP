import Foundation
import SwiftData

@Model
final class Trip {
    var date: Date
    var distanceMeters: Double
    var durationSeconds: TimeInterval
    var averageSpeedKmH: Double

    init(date: Date, distanceMeters: Double, durationSeconds: TimeInterval, averageSpeedKmH: Double) {
        self.date = date
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.averageSpeedKmH = averageSpeedKmH
    }

    var distanceKm: Double {
        distanceMeters / 1000.0
    }

    var formattedDuration: String {
        let hours = Int(durationSeconds) / 3600
        let minutes = (Int(durationSeconds) % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, minutes)
        }
        return String(format: "%dm", minutes)
    }
}

extension ModelContainer {
    static let appGroupID = "group.com.gok24code.bikeplay"

    // Ana app ve widget'ın ortak eriştiği App Group tabanlı SwiftData deposu
    static let shared: ModelContainer = {
        guard let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            fatalError("App Group bulunamadı: \(appGroupID)")
        }

        // Depoyu container köküne koyuyoruz. Varsayılan "Library/Application Support"
        // klasörü ilk açılışta oluşmadığı için CoreData gürültülü hata basıyordu.
        let storeURL = groupURL.appendingPathComponent("BikePlay.store")
        let config = ModelConfiguration(url: storeURL)

        do {
            return try ModelContainer(for: Trip.self, configurations: config)
        } catch {
            fatalError("Paylaşımlı SwiftData deposu oluşturulamadı: \(error)")
        }
    }()
}
