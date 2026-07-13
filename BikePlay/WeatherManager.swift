import Foundation
import CoreLocation
internal import Combine
import SwiftUI

@MainActor
class WeatherManager: ObservableObject {
    @Published var temperature: String = "--°C"
    @Published var conditionIcon: String = "cloud.sun.fill"

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(coordinate.latitude)&longitude=\(coordinate.longitude)&current=temperature_2m,weather_code"

        guard let url = URL(string: urlString) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let current = json["current"] as? [String: Any],
               let temp = current["temperature_2m"] as? Double,
               let weatherCode = current["weather_code"] as? Int {

                self.temperature = "\(Int(round(temp)))°C"

                switch weatherCode {
                case 0: self.conditionIcon = "sun.max.fill"
                case 1, 2, 3: self.conditionIcon = "cloud.sun.fill"
                case 45, 48: self.conditionIcon = "cloud.fog.fill"
                case 51...67, 80...82: self.conditionIcon = "cloud.rain.fill"
                case 71...77, 85, 86: self.conditionIcon = "snowflake"
                case 95...99: self.conditionIcon = "cloud.bolt.rain.fill"
                default: self.conditionIcon = "cloud.fill"
                }
            }
        } catch {
            print("Hava durumu çekilemedi: \(error.localizedDescription)")
            self.temperature = "N/A"
        }
    }
}
