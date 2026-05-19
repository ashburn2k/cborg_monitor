import AppIntents
import SwiftUI
import WidgetKit

struct CBORGUsageEntry: TimelineEntry {
    let date: Date
    let snapshot: CBORGUsageSnapshot
}

struct CBORGUsageWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "CBORG Usage"
    static let description = IntentDescription("Shows the latest cached CBORG API usage.")
}

struct CBORGUsageProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CBORGUsageEntry {
        CBORGUsageEntry(date: .now, snapshot: .preview)
    }

    func snapshot(for configuration: CBORGUsageWidgetIntent, in context: Context) async -> CBORGUsageEntry {
        if context.isPreview {
            return CBORGUsageEntry(date: .now, snapshot: .preview)
        }

        return CBORGUsageEntry(date: .now, snapshot: CBORGUsageStore.loadSnapshot() ?? .empty)
    }

    func timeline(for configuration: CBORGUsageWidgetIntent, in context: Context) async -> Timeline<CBORGUsageEntry> {
        let snapshot = CBORGUsageStore.loadSnapshot() ?? .empty
        let entry = CBORGUsageEntry(date: .now, snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: .now) ?? .now.addingTimeInterval(300)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct CBORGUsageMonitorWidget: Widget {
    let kind = "CBORGUsageMonitorWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CBORGUsageWidgetIntent.self, provider: CBORGUsageProvider()) { entry in
            CBORGUsageWidgetView(entry: entry)
        }
        .configurationDisplayName("CBORG Usage")
        .description("Shows CBORG API spend and monthly budget.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct CBORGUsageWidgetView: View {
    @Environment(\.widgetFamily) private var family

    let entry: CBORGUsageEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family.stackSpacing) {
            header

            if entry.snapshot.hasData {
                usageBody
            } else {
                setupBody
            }
        }
        .padding(family.contentPadding)
        .containerBackground(for: .widget) {
            Color(red: 0.08, green: 0.09, blue: 0.08)
        }
    }

    private var header: some View {
        HStack(spacing: 7) {
            Image(systemName: entry.snapshot.health.symbolName)
                .font(.system(size: family == .systemSmall ? 11 : 13, weight: .bold))
                .foregroundStyle(entry.snapshot.health.color)

            Text("CBORG")
                .font(.system(size: family == .systemSmall ? 13 : 15, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 4)

            Text(CBORGFormatters.compactTime(entry.snapshot.checkedAt))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.56))
                .lineLimit(1)
        }
    }

    private var usageBody: some View {
        Group {
            if family == .systemSmall {
                smallUsage
            } else {
                wideUsage
            }
        }
    }

    private var smallUsage: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center) {
                UsageRing(percent: entry.snapshot.displayPercent, color: entry.snapshot.health.color)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text(CBORGFormatters.percent(entry.snapshot.displayPercent))
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                    Text("used")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            Text(CBORGFormatters.currency(entry.snapshot.displaySpend))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            Text(CBORGFormatters.resetDate(entry.snapshot.displayReset))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private var wideUsage: some View {
        HStack(spacing: family == .systemLarge ? 18 : 14) {
            UsageRing(percent: entry.snapshot.displayPercent, color: entry.snapshot.health.color)
                .frame(width: family == .systemLarge ? 88 : 68, height: family == .systemLarge ? 88 : 68)

            VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 7) {
                HStack(alignment: .firstTextBaseline, spacing: 7) {
                    Text(CBORGFormatters.percent(entry.snapshot.displayPercent))
                        .font(.system(size: family == .systemLarge ? 38 : 30, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)
                    Text("used")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.62))
                }

                metricRow("Spend", CBORGFormatters.currency(entry.snapshot.displaySpend))
                metricRow("Budget", CBORGFormatters.currency(entry.snapshot.displayBudget))
                metricRow("Reset", CBORGFormatters.resetDate(entry.snapshot.displayReset))

                if family == .systemLarge {
                    metricRow("Key", entry.snapshot.keyName ?? "Unknown")
                }
            }
        }
    }

    private var setupBody: some View {
        VStack(alignment: .leading, spacing: 7) {
            Spacer(minLength: 0)
            Image(systemName: "key.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.blue)
            Text("Open App")
                .font(.system(size: family == .systemSmall ? 18 : 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Save CBORG key")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.62))
            Spacer(minLength: 0)
        }
    }

    private func metricRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(.white.opacity(0.54))
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .font(.system(size: family == .systemLarge ? 12 : 11))
    }
}

private struct UsageRing: View {
    let percent: Double?
    let color: Color

    private var progress: Double {
        min(max((percent ?? 0) / 100, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(.white.opacity(0.14), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((percent ?? 0).rounded()))")
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
        }
    }
}

private extension WidgetFamily {
    var contentPadding: CGFloat {
        switch self {
        case .systemSmall:
            return 12
        case .systemLarge, .systemExtraLarge:
            return 16
        default:
            return 14
        }
    }

    var stackSpacing: CGFloat {
        switch self {
        case .systemSmall:
            return 8
        default:
            return 10
        }
    }
}
