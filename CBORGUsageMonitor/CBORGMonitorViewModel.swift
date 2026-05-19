import Foundation
import SwiftUI
import WidgetKit

@MainActor
final class CBORGMonitorViewModel: ObservableObject {
    @Published var snapshot: CBORGUsageSnapshot
    @Published var apiKeyInput = ""
    @Published var endpoint: String
    @Published var keyAlias: String
    @Published var thresholdPercent: Double
    @Published var refreshIntervalSeconds: Double
    @Published var keyIsSaved = false
    @Published var environmentKeyAvailable = false
    @Published var isRefreshing = false
    @Published var statusMessage = ""

    private var timer: Timer?

    init() {
        snapshot = CBORGUsageStore.loadSnapshot() ?? .empty
        endpoint = CBORGUsageStore.loadEndpoint()
        keyAlias = CBORGUsageStore.loadKeyAlias()
        thresholdPercent = CBORGUsageStore.loadThresholdPercent()
        refreshIntervalSeconds = CBORGUsageStore.loadRefreshInterval()
        refreshKeyStatus()
        seedKeyFromEnvironmentIfPossible()
        startTimer()

        if keyIsSaved {
            Task { await refresh() }
        }
    }

    var menuTitle: String {
        guard let percent = snapshot.displayPercent else {
            return "CBORG"
        }
        return "CBORG \(Int(percent.rounded()))%"
    }

    var canRefresh: Bool {
        keyIsSaved && !isRefreshing
    }

    func refreshKeyStatus() {
        do {
            keyIsSaved = try CBORGKeychain.loadAPIKey() != nil
        } catch {
            keyIsSaved = false
            statusMessage = error.localizedDescription
        }
    }

    func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            statusMessage = "Paste a CBORG API key first."
            return
        }

        do {
            try CBORGKeychain.saveAPIKey(trimmed)
            apiKeyInput = ""
            keyIsSaved = true
            statusMessage = "API key saved in Keychain."
            Task { await refresh() }
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        do {
            try CBORGKeychain.deleteAPIKey()
            keyIsSaved = false
            apiKeyInput = ""
            statusMessage = "API key removed from Keychain."
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    func saveSettings() {
        endpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        keyAlias = keyAlias.trimmingCharacters(in: .whitespacesAndNewlines)
        thresholdPercent = max(1, min(thresholdPercent, 100))
        refreshIntervalSeconds = max(60, refreshIntervalSeconds)

        CBORGUsageStore.saveEndpoint(endpoint)
        CBORGUsageStore.saveKeyAlias(keyAlias)
        CBORGUsageStore.saveThresholdPercent(thresholdPercent)
        CBORGUsageStore.saveRefreshInterval(refreshIntervalSeconds)
        startTimer()
        statusMessage = "Settings saved."

        if keyIsSaved {
            Task { await refresh() }
        }
    }

    func refresh() async {
        guard !isRefreshing else { return }
        guard keyIsSaved else {
            statusMessage = "Save a CBORG API key first."
            return
        }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            guard let apiKey = try CBORGKeychain.loadAPIKey() else {
                keyIsSaved = false
                throw CBORGUsageClientError.emptyKey
            }
            let client = CBORGUsageClient(endpoint: endpoint)
            let freshSnapshot = try await client.fetch(
                apiKey: apiKey,
                preferredKeyAlias: keyAlias,
                thresholdPercent: thresholdPercent
            )
            snapshot = freshSnapshot
            CBORGUsageStore.saveSnapshot(freshSnapshot)
            WidgetCenter.shared.reloadAllTimelines()
            statusMessage = "Updated \(CBORGFormatters.relativeTime(freshSnapshot.checkedAt))."
        } catch {
            var failedSnapshot = snapshot.hasData ? snapshot : .empty
            failedSnapshot.errorMessage = error.localizedDescription
            failedSnapshot.thresholdPercent = thresholdPercent
            snapshot = failedSnapshot
            CBORGUsageStore.saveSnapshot(failedSnapshot)
            WidgetCenter.shared.reloadAllTimelines()
            statusMessage = error.localizedDescription
        }
    }

    func clearCache() {
        CBORGUsageStore.clearSnapshot()
        snapshot = .empty
        statusMessage = "Cached usage cleared."
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: refreshIntervalSeconds, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
        timer?.tolerance = min(30, refreshIntervalSeconds * 0.1)
    }

    private func seedKeyFromEnvironmentIfPossible() {
        let envKey = ProcessInfo.processInfo.environment["CBORG_API_KEY"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        environmentKeyAvailable = envKey?.isEmpty == false

        guard !keyIsSaved, let envKey, !envKey.isEmpty else {
            return
        }

        do {
            try CBORGKeychain.saveAPIKey(envKey)
            keyIsSaved = true
            statusMessage = "API key imported from environment."
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
