//
//  BikePlayLiveNotify.swift
//  BikePlayLiveNotify
//
//  Created by Göktuğ Toyguc on 13.07.2026.
//

import WidgetKit
import SwiftUI
import SwiftData
import Charts

struct DayKm: Identifiable {
    let day: Date   // günün başlangıcı (startOfDay)
    let km: Double
    var id: Date { day }
}

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), daily: Provider.sampleData())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), daily: await Provider.currentMonthDaily())
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = SimpleEntry(date: Date(), daily: await Provider.currentMonthDaily())
        return Timeline(entries: [entry], policy: .atEnd)
    }

    // Paylaşımlı SwiftData deposundan bu ayın günlük toplam km'lerini çıkarır
    @MainActor
    static func currentMonthDaily() -> [DayKm] {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)

        let context = ModelContext(.shared)
        guard let trips = try? context.fetch(FetchDescriptor<Trip>()) else { return [] }

        var kmByDay: [Date: Double] = [:]
        for trip in trips {
            let comps = calendar.dateComponents([.year, .month], from: trip.date)
            guard comps.year == year, comps.month == month else { continue }
            let start = calendar.startOfDay(for: trip.date)
            kmByDay[start, default: 0] += trip.distanceKm
        }
        return kmByDay
            .map { DayKm(day: $0.key, km: $0.value) }
            .sorted { $0.day < $1.day }
    }

    // Preview / placeholder için örnek veri
    static func sampleData() -> [DayKm] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<28).compactMap { offset in
            guard offset % 2 == 0 || offset % 3 == 0 else { return nil }
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            return DayKm(day: day, km: Double.random(in: 3...18))
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let daily: [DayKm]
}

struct BikePlayLiveNotifyEntryView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallTodayView(daily: entry.daily)
        case .systemMedium:
            WeeklyChartView(daily: entry.daily)
        default:
            MonthlyChartView(daily: entry.daily)
        }
    }
}

// MARK: - Small: Bugünün toplamı

struct SmallTodayView: View {
    let daily: [DayKm]

    private var todayKm: Double {
        let calendar = Calendar.current
        return daily.first { calendar.isDateInToday($0.day) }?.km ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "bicycle")
                    .font(.system(size: 13, weight: .bold))
                Text("BUGÜN")
                    .font(.system(size: 11, weight: .black))
            }
            .foregroundColor(.green)

            Spacer()

            Text(String(format: "%.1f", todayKm))
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("KM")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Medium: Son 7 gün çizgi grafiği

struct WeeklyChartView: View {
    let daily: [DayKm]

    private var points: [DayKm] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today)!
            let km = daily.first { calendar.isDate($0.day, inSameDayAs: day) }?.km ?? 0
            return DayKm(day: day, km: km)
        }
    }

    private var totalKm: Double { points.reduce(0) { $0 + $1.km } }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("SON 7 GÜN")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.green)
                Spacer()
                Text(String(format: "%.1f km", totalKm))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            if totalKm > 0 {
                RideChart(points: points, xStride: 1, xFormat: .dateTime.weekday(.narrow))
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var emptyState: some View {
        Text("Bu hafta henüz sürüş yok")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.gray)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Large: Bu ayın günlük çizgi grafiği

struct MonthlyChartView: View {
    let daily: [DayKm]

    private var points: [DayKm] {
        let calendar = Calendar.current
        let now = Date()
        let comps = calendar.dateComponents([.year, .month], from: now)
        let range = calendar.range(of: .day, in: .month, for: now) ?? 1..<32
        return range.map { day in
            let date = calendar.date(from: DateComponents(year: comps.year, month: comps.month, day: day))!
            let km = daily.first { calendar.isDate($0.day, inSameDayAs: date) }?.km ?? 0
            return DayKm(day: date, km: km)
        }
    }

    private var totalKm: Double { points.reduce(0) { $0 + $1.km } }
    private var bestDay: DayKm? { points.max { $0.km < $1.km } }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("BU AY")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.green)
                    Text(Date().formatted(.dateTime.month(.wide).year()))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(format: "%.1f km", totalKm))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("toplam")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.gray)
                }
            }

            if totalKm > 0 {
                RideChart(points: points, xStride: 5, xFormat: .dateTime.day())

                if let best = bestDay, best.km > 0 {
                    Text("En iyi gün: \(best.day.formatted(.dateTime.day().month())) · \(String(format: "%.1f km", best.km))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.green.opacity(0.85))
                }
            } else {
                Text("Bu ay henüz sürüş yok")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Ortak grafik bileşeni

struct RideChart: View {
    let points: [DayKm]
    let xStride: Int
    let xFormat: Date.FormatStyle

    var body: some View {
        Chart(points) { point in
            AreaMark(
                x: .value("Gün", point.day, unit: .day),
                y: .value("KM", point.km)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(colors: [.green.opacity(0.35), .green.opacity(0.02)],
                               startPoint: .top, endPoint: .bottom)
            )

            LineMark(
                x: .value("Gün", point.day, unit: .day),
                y: .value("KM", point.km)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(.green)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day, count: xStride)) { _ in
                AxisGridLine().foregroundStyle(.gray.opacity(0.12))
                AxisValueLabel(format: xFormat)
                    .foregroundStyle(.gray)
                    .font(.system(size: 8))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(.gray.opacity(0.12))
                AxisValueLabel()
                    .foregroundStyle(.gray)
                    .font(.system(size: 8))
            }
        }
    }
}

struct BikePlayLiveNotify: Widget {
    let kind: String = "BikePlayLiveNotify"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            BikePlayLiveNotifyEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .configurationDisplayName("BikePlay Sürüş Özeti")
        .description("Günlük, haftalık ve aylık sürüş istatistiklerin.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview("Small", as: .systemSmall) {
    BikePlayLiveNotify()
} timeline: {
    SimpleEntry(date: .now, daily: Provider.sampleData())
}

#Preview("Medium", as: .systemMedium) {
    BikePlayLiveNotify()
} timeline: {
    SimpleEntry(date: .now, daily: Provider.sampleData())
}

#Preview("Large", as: .systemLarge) {
    BikePlayLiveNotify()
} timeline: {
    SimpleEntry(date: .now, daily: Provider.sampleData())
}
