import Foundation

enum CBORGAppGroup {
    static let suiteName = "group.dev.local.CBORGUsageMonitor"

    static var defaults: UserDefaults {
        UserDefaults(suiteName: suiteName) ?? .standard
    }
}

enum CBORGUsageStore {
    private static let snapshotKey = "cborg.usage.snapshot.v1"
    private static let thresholdKey = "cborg.usage.thresholdPercent"
    private static let intervalKey = "cborg.usage.refreshIntervalSeconds"
    private static let endpointKey = "cborg.usage.endpoint"
    private static let keyAliasKey = "cborg.usage.keyAlias"

    static let defaultEndpoint = "https://api.cborg.lbl.gov/user/info"
    static let defaultThresholdPercent = 80.0
    static let defaultRefreshInterval = 300.0

    static func saveSnapshot(_ snapshot: CBORGUsageSnapshot) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(snapshot) else { return }
        CBORGAppGroup.defaults.set(data, forKey: snapshotKey)
    }

    static func loadSnapshot() -> CBORGUsageSnapshot? {
        guard let data = CBORGAppGroup.defaults.data(forKey: snapshotKey) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(CBORGUsageSnapshot.self, from: data)
    }

    static func clearSnapshot() {
        CBORGAppGroup.defaults.removeObject(forKey: snapshotKey)
    }

    static func saveThresholdPercent(_ value: Double) {
        CBORGAppGroup.defaults.set(value, forKey: thresholdKey)
    }

    static func loadThresholdPercent() -> Double {
        let value = CBORGAppGroup.defaults.double(forKey: thresholdKey)
        return value > 0 ? value : defaultThresholdPercent
    }

    static func saveRefreshInterval(_ value: Double) {
        CBORGAppGroup.defaults.set(value, forKey: intervalKey)
    }

    static func loadRefreshInterval() -> Double {
        let value = CBORGAppGroup.defaults.double(forKey: intervalKey)
        return value >= 60 ? value : defaultRefreshInterval
    }

    static func saveEndpoint(_ value: String) {
        CBORGAppGroup.defaults.set(value, forKey: endpointKey)
    }

    static func loadEndpoint() -> String {
        let value = CBORGAppGroup.defaults.string(forKey: endpointKey) ?? ""
        return value.isEmpty ? defaultEndpoint : value
    }

    static func saveKeyAlias(_ value: String) {
        CBORGAppGroup.defaults.set(value, forKey: keyAliasKey)
    }

    static func loadKeyAlias() -> String {
        CBORGAppGroup.defaults.string(forKey: keyAliasKey) ?? ""
    }
}
