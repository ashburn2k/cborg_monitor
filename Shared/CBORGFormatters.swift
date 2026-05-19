import Foundation

enum CBORGFormatters {
    private static let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 4
        formatter.minimumFractionDigits = 2
        return formatter
    }()

    private static let percentFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    static func currency(_ value: Double?) -> String {
        guard let value else { return "Unknown" }
        return currencyFormatter.string(from: NSNumber(value: value)) ?? String(format: "$%.4f", value)
    }

    static func percent(_ value: Double?) -> String {
        guard let value else { return "Unknown" }
        return percentFormatter.string(from: NSNumber(value: value / 100)) ?? String(format: "%.1f%%", value)
    }

    static func compactTime(_ date: Date?) -> String {
        guard let date else { return "Never" }
        return date.formatted(.dateTime.hour().minute())
    }

    static func relativeTime(_ date: Date?) -> String {
        guard let date else { return "Never checked" }
        return date.formatted(.relative(presentation: .named))
    }

    static func resetDate(_ rawValue: String?) -> String {
        guard let rawValue, !rawValue.isEmpty else { return "Unknown reset" }
        if let date = ISO8601DateFormatter().date(from: rawValue) {
            return date.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        }
        return rawValue
    }
}
