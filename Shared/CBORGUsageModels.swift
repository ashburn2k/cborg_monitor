import Foundation
import SwiftUI

struct CBORGUsageSnapshot: Codable, Equatable, Sendable {
    var checkedAt: Date?
    var userID: String?
    var userAlias: String?
    var userEmail: String?
    var userSpend: Double?
    var userMaxBudget: Double?
    var userBudgetUsedPercent: Double?
    var userBudgetDuration: String?
    var userBudgetResetAt: String?
    var userRPM: Int?
    var userTPM: Int?
    var keyAlias: String?
    var keyName: String?
    var keySpend: Double?
    var keyMaxBudget: Double?
    var keyBudgetUsedPercent: Double?
    var keyBudgetDuration: String?
    var keyBudgetResetAt: String?
    var keyLastActive: String?
    var keyRPM: Int?
    var keyTPM: Int?
    var keyCount: Int
    var thresholdPercent: Double
    var errorMessage: String?

    static let empty = CBORGUsageSnapshot(
        checkedAt: nil,
        userID: nil,
        userAlias: nil,
        userEmail: nil,
        userSpend: nil,
        userMaxBudget: nil,
        userBudgetUsedPercent: nil,
        userBudgetDuration: nil,
        userBudgetResetAt: nil,
        userRPM: nil,
        userTPM: nil,
        keyAlias: nil,
        keyName: nil,
        keySpend: nil,
        keyMaxBudget: nil,
        keyBudgetUsedPercent: nil,
        keyBudgetDuration: nil,
        keyBudgetResetAt: nil,
        keyLastActive: nil,
        keyRPM: nil,
        keyTPM: nil,
        keyCount: 0,
        thresholdPercent: 80,
        errorMessage: nil
    )

    static let preview = CBORGUsageSnapshot(
        checkedAt: .now,
        userID: "cborg-user@lbl.gov",
        userAlias: "cborg-user",
        userEmail: "cborg-user@lbl.gov",
        userSpend: 19.99,
        userMaxBudget: 150,
        userBudgetUsedPercent: 13.3,
        userBudgetDuration: "1mo",
        userBudgetResetAt: "2026-06-01T00:00:00Z",
        userRPM: nil,
        userTPM: nil,
        keyAlias: "cborg-user@lbl.gov",
        keyName: "sk-...diww",
        keySpend: 19.99,
        keyMaxBudget: nil,
        keyBudgetUsedPercent: nil,
        keyBudgetDuration: nil,
        keyBudgetResetAt: nil,
        keyLastActive: nil,
        keyRPM: nil,
        keyTPM: nil,
        keyCount: 1,
        thresholdPercent: 80,
        errorMessage: nil
    )

    var hasData: Bool {
        checkedAt != nil
    }

    var isOverThreshold: Bool {
        guard let percent = userBudgetUsedPercent else { return false }
        return percent >= thresholdPercent
    }

    var health: CBORGUsageHealth {
        if errorMessage != nil { return .error }
        if !hasData { return .needsKey }
        if isOverThreshold { return .warning }
        return .ok
    }

    var displaySpend: Double? {
        userSpend ?? keySpend
    }

    var displayBudget: Double? {
        userMaxBudget ?? keyMaxBudget
    }

    var displayPercent: Double? {
        userBudgetUsedPercent ?? keyBudgetUsedPercent
    }

    var displayReset: String? {
        userBudgetResetAt ?? keyBudgetResetAt
    }
}

enum CBORGUsageHealth: Sendable {
    case ok
    case warning
    case error
    case needsKey

    var title: String {
        switch self {
        case .ok:
            return "OK"
        case .warning:
            return "Watch"
        case .error:
            return "Error"
        case .needsKey:
            return "Setup"
        }
    }

    var symbolName: String {
        switch self {
        case .ok:
            return "checkmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "xmark.octagon.fill"
        case .needsKey:
            return "key.fill"
        }
    }

    var color: Color {
        switch self {
        case .ok:
            return .green
        case .warning:
            return .orange
        case .error:
            return .red
        case .needsKey:
            return .blue
        }
    }
}

struct CBORGUserInfoResponse: Decodable, Sendable {
    var keys: [CBORGAPIKeyInfo]
    var userID: String?
    var userInfo: CBORGUserInfo?

    enum CodingKeys: String, CodingKey {
        case keys
        case userID = "user_id"
        case userInfo = "user_info"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keys = try container.decodeIfPresent([CBORGAPIKeyInfo].self, forKey: .keys) ?? []
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
        userInfo = try container.decodeIfPresent(CBORGUserInfo.self, forKey: .userInfo)
    }

    func snapshot(preferredKeyAlias: String?, thresholdPercent: Double) -> CBORGUsageSnapshot {
        let keyInfo = chooseKey(preferredAlias: preferredKeyAlias)
        let userSpend = userInfo?.spend
        let userMaxBudget = userInfo?.maxBudget
        let keySpend = keyInfo?.spend
        let keyMaxBudget = keyInfo?.maxBudget

        return CBORGUsageSnapshot(
            checkedAt: .now,
            userID: userID ?? userInfo?.userID,
            userAlias: userInfo?.userAlias,
            userEmail: userInfo?.userEmail,
            userSpend: userSpend,
            userMaxBudget: userMaxBudget,
            userBudgetUsedPercent: Self.percent(spend: userSpend, budget: userMaxBudget),
            userBudgetDuration: userInfo?.budgetDuration,
            userBudgetResetAt: userInfo?.budgetResetAt,
            userRPM: userInfo?.rpmLimit,
            userTPM: userInfo?.tpmLimit,
            keyAlias: keyInfo?.keyAlias,
            keyName: Self.redact(keyInfo?.keyName),
            keySpend: keySpend,
            keyMaxBudget: keyMaxBudget,
            keyBudgetUsedPercent: Self.percent(spend: keySpend, budget: keyMaxBudget),
            keyBudgetDuration: keyInfo?.budgetDuration,
            keyBudgetResetAt: keyInfo?.budgetResetAt,
            keyLastActive: keyInfo?.lastActive,
            keyRPM: keyInfo?.rpmLimit,
            keyTPM: keyInfo?.tpmLimit,
            keyCount: keys.count,
            thresholdPercent: thresholdPercent,
            errorMessage: nil
        )
    }

    private func chooseKey(preferredAlias: String?) -> CBORGAPIKeyInfo? {
        if let preferredAlias, !preferredAlias.isEmpty {
            return keys.first { $0.keyAlias == preferredAlias } ?? keys.first
        }
        return keys.first
    }

    private static func percent(spend: Double?, budget: Double?) -> Double? {
        guard let spend, let budget, budget > 0 else { return nil }
        return (spend / budget) * 100
    }

    private static func redact(_ keyName: String?) -> String? {
        guard let keyName, !keyName.isEmpty else { return nil }
        if keyName.contains("...") || keyName.count <= 10 {
            return keyName
        }
        return "\(keyName.prefix(3))...\(keyName.suffix(4))"
    }
}

struct CBORGUserInfo: Decodable, Sendable {
    var spend: Double?
    var maxBudget: Double?
    var budgetDuration: String?
    var budgetResetAt: String?
    var rpmLimit: Int?
    var tpmLimit: Int?
    var userAlias: String?
    var userEmail: String?
    var userID: String?

    enum CodingKeys: String, CodingKey {
        case spend
        case maxBudget = "max_budget"
        case budgetDuration = "budget_duration"
        case budgetResetAt = "budget_reset_at"
        case rpmLimit = "rpm_limit"
        case tpmLimit = "tpm_limit"
        case userAlias = "user_alias"
        case userEmail = "user_email"
        case userID = "user_id"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spend = try container.decodeFlexibleDouble(forKey: .spend)
        maxBudget = try container.decodeFlexibleDouble(forKey: .maxBudget)
        budgetDuration = try container.decodeIfPresent(String.self, forKey: .budgetDuration)
        budgetResetAt = try container.decodeIfPresent(String.self, forKey: .budgetResetAt)
        rpmLimit = try container.decodeFlexibleInt(forKey: .rpmLimit)
        tpmLimit = try container.decodeFlexibleInt(forKey: .tpmLimit)
        userAlias = try container.decodeIfPresent(String.self, forKey: .userAlias)
        userEmail = try container.decodeIfPresent(String.self, forKey: .userEmail)
        userID = try container.decodeIfPresent(String.self, forKey: .userID)
    }
}

struct CBORGAPIKeyInfo: Decodable, Sendable {
    var keyAlias: String?
    var keyName: String?
    var spend: Double?
    var maxBudget: Double?
    var budgetDuration: String?
    var budgetResetAt: String?
    var lastActive: String?
    var rpmLimit: Int?
    var tpmLimit: Int?

    enum CodingKeys: String, CodingKey {
        case keyAlias = "key_alias"
        case keyName = "key_name"
        case spend
        case maxBudget = "max_budget"
        case budgetDuration = "budget_duration"
        case budgetResetAt = "budget_reset_at"
        case lastActive = "last_active"
        case rpmLimit = "rpm_limit"
        case tpmLimit = "tpm_limit"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyAlias = try container.decodeIfPresent(String.self, forKey: .keyAlias)
        keyName = try container.decodeIfPresent(String.self, forKey: .keyName)
        spend = try container.decodeFlexibleDouble(forKey: .spend)
        maxBudget = try container.decodeFlexibleDouble(forKey: .maxBudget)
        budgetDuration = try container.decodeIfPresent(String.self, forKey: .budgetDuration)
        budgetResetAt = try container.decodeIfPresent(String.self, forKey: .budgetResetAt)
        lastActive = try container.decodeIfPresent(String.self, forKey: .lastActive)
        rpmLimit = try container.decodeFlexibleInt(forKey: .rpmLimit)
        tpmLimit = try container.decodeFlexibleInt(forKey: .tpmLimit)
    }
}

extension KeyedDecodingContainer {
    func decodeFlexibleDouble(forKey key: Key) throws -> Double? {
        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return value
        }
        if let string = try decodeIfPresent(String.self, forKey: key) {
            return Double(string)
        }
        return nil
    }

    func decodeFlexibleInt(forKey key: Key) throws -> Int? {
        if let value = try decodeIfPresent(Int.self, forKey: key) {
            return value
        }
        if let value = try decodeIfPresent(Double.self, forKey: key) {
            return Int(value)
        }
        if let string = try decodeIfPresent(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }
}
