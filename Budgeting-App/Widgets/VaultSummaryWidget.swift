import WidgetKit
import SwiftUI

struct WidgetSummaryData: Codable {
    var monthlyBudget: Double
    var balance: Double
    var needsProgress: Double
    var wantsProgress: Double
    var savingsProgress: Double
    var nextTitle: String
    var nextDateText: String
    var updatedAt: Date
}

struct SummaryEntry: TimelineEntry {
    let date: Date
    let data: WidgetSummaryData
}

struct SummaryProvider: TimelineProvider {
    private let appGroupId = "group.lk.uni.vaultapp"
    private let storageKey = "widget_summary"

    func placeholder(in context: Context) -> SummaryEntry {
        SummaryEntry(date: Date(), data: sampleData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SummaryEntry) -> Void) {
        completion(SummaryEntry(date: Date(), data: loadData() ?? sampleData()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SummaryEntry>) -> Void) {
        let data = loadData() ?? sampleData()
        let entry = SummaryEntry(date: Date(), data: data)
        let timeline = Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(30 * 60)))
        completion(timeline)
    }

    private func loadData() -> WidgetSummaryData? {
        guard let defaults = UserDefaults(suiteName: appGroupId) else { return nil }
        guard let data = defaults.data(forKey: storageKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSummaryData.self, from: data)
    }

    func sampleData() -> WidgetSummaryData {
        WidgetSummaryData(
            monthlyBudget: 45000,
            balance: 18250,
            needsProgress: 0.62,
            wantsProgress: 0.31,
            savingsProgress: 0.45,
            nextTitle: "Upcoming shift",
            nextDateText: "Apr 06 · Library Assistant",
            updatedAt: Date()
        )
    }
}

struct VaultSummaryWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: SummaryProvider.Entry

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.043, green: 0.102, blue: 0.165),
                    Color(red: 0.067, green: 0.169, blue: 0.275)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            glassOverlay

            switch family {
            case .systemSmall:
                smallView
            default:
                mediumView
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(red: 0.043, green: 0.102, blue: 0.165),
                    Color(red: 0.067, green: 0.169, blue: 0.275)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .contentMarginsDisabled()
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            Text("Balance")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(Color.white.opacity(0.7))
            Text(formatCurrency(entry.data.balance))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)
                .minimumScaleFactor(0.7)

            ProgressRow(
                label: "Needs",
                value: entry.data.needsProgress,
                color: Color(red: 0.231, green: 0.510, blue: 0.965)
            )
        }
        .padding(14)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                header
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Balance")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text(formatCurrency(entry.data.balance))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                }
            }

            HStack(spacing: 10) {
                ProgressRow(label: "Needs", value: entry.data.needsProgress, color: Color(red: 0.231, green: 0.510, blue: 0.965))
                ProgressRow(label: "Wants", value: entry.data.wantsProgress, color: Color(red: 0.545, green: 0.361, blue: 0.965))
                ProgressRow(label: "Savings", value: entry.data.savingsProgress, color: Color(red: 0.133, green: 0.773, blue: 0.369))
            }

            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.7))
                Text(entry.data.nextTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.85))
                Text(entry.data.nextDateText)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.white.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .padding(14)
    }

    private var header: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(LinearGradient(
                    colors: [
                        Color(red: 0.376, green: 0.647, blue: 0.980),
                        Color(red: 0.145, green: 0.388, blue: 0.922)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 10, height: 10)
            Text("Vault Summary")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private var glassOverlay: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .overlay(
                LinearGradient(
                    colors: [Color.white.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }

    private func formatCurrency(_ value: Double) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        let num = fmt.string(from: NSNumber(value: value)) ?? "0"
        return "LKR \(num)"
    }
}

struct ProgressRow: View {
    let label: String
    let value: Double
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.85))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.12)).frame(height: 6)
                Capsule().fill(color).frame(width: max(4, CGFloat(value) * 60), height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct VaultSummaryWidget: Widget {
    let kind: String = "VaultSummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SummaryProvider()) { entry in
            VaultSummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vault Summary")
        .description("Budget status, balance, and upcoming items at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct WidgetPreview_Previews: PreviewProvider {
    static var previews: some View {
        VaultSummaryWidgetEntryView(entry: SummaryEntry(date: Date(), data: SummaryProvider().sampleData()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
