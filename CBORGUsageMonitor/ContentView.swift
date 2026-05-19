import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var monitor: CBORGMonitorViewModel

    var body: some View {
        HStack(spacing: 0) {
            settingsPanel
                .frame(width: 360)

            Divider()

            usagePanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 900, minHeight: 560)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var settingsPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Label("CBORG Usage", systemImage: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                Text(monitor.keyIsSaved ? "Key saved in Keychain" : "Key not saved")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(monitor.keyIsSaved ? Color.green : Color.orange)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Connection")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                SecureField("CBORG API key", text: $monitor.apiKeyInput)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 8) {
                    Button {
                        monitor.saveAPIKey()
                    } label: {
                        Label("Save Key", systemImage: "key.fill")
                    }
                    .buttonStyle(.borderedProminent)

                    Button(role: .destructive) {
                        monitor.deleteAPIKey()
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                    .disabled(!monitor.keyIsSaved)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Monitor")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.secondary)

                TextField("Endpoint", text: $monitor.endpoint)
                    .textFieldStyle(.roundedBorder)

                TextField("Key alias", text: $monitor.keyAlias)
                    .textFieldStyle(.roundedBorder)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Alert")
                        Spacer()
                        Text(CBORGFormatters.percent(monitor.thresholdPercent))
                            .fontWeight(.bold)
                    }
                    .font(.system(size: 12, weight: .medium))
                    Slider(value: $monitor.thresholdPercent, in: 1...100, step: 1)
                }

                Picker("Refresh", selection: $monitor.refreshIntervalSeconds) {
                    Text("1 min").tag(60.0)
                    Text("5 min").tag(300.0)
                    Text("15 min").tag(900.0)
                    Text("30 min").tag(1800.0)
                }
                .pickerStyle(.segmented)

                Button {
                    monitor.saveSettings()
                } label: {
                    Label("Save Settings", systemImage: "checkmark.circle")
                }
                .buttonStyle(.bordered)
            }

            HStack(spacing: 8) {
                Button {
                    Task { await monitor.refresh() }
                } label: {
                    if monitor.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh Now", systemImage: "arrow.clockwise")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!monitor.canRefresh)

                Button {
                    monitor.clearCache()
                } label: {
                    Label("Clear Cache", systemImage: "xmark.bin")
                }
                .buttonStyle(.bordered)
            }

            if !monitor.statusMessage.isEmpty {
                Text(monitor.statusMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(monitor.snapshot.errorMessage == nil ? Color.secondary : Color.orange)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(22)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var usagePanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(monitor.snapshot.userID ?? "CBORG Account")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text("Checked \(CBORGFormatters.relativeTime(monitor.snapshot.checkedAt))")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Label(monitor.snapshot.health.title, systemImage: monitor.snapshot.health.symbolName)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(monitor.snapshot.health.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(monitor.snapshot.health.color.opacity(0.12), in: Capsule())
            }

            HStack(spacing: 14) {
                UsageMetricCard(
                    title: "Budget Used",
                    value: CBORGFormatters.percent(monitor.snapshot.displayPercent),
                    detail: "Alert at \(CBORGFormatters.percent(monitor.thresholdPercent))",
                    systemImage: "gauge.with.dots.needle.67percent",
                    color: monitor.snapshot.health.color
                )

                UsageMetricCard(
                    title: "Spend",
                    value: CBORGFormatters.currency(monitor.snapshot.displaySpend),
                    detail: "This budget cycle",
                    systemImage: "dollarsign.circle.fill",
                    color: .green
                )

                UsageMetricCard(
                    title: "Budget",
                    value: CBORGFormatters.currency(monitor.snapshot.displayBudget),
                    detail: CBORGFormatters.resetDate(monitor.snapshot.displayReset),
                    systemImage: "calendar.badge.clock",
                    color: .blue
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Account")
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                usageRow("User alias", monitor.snapshot.userAlias ?? "Unknown")
                usageRow("User email", monitor.snapshot.userEmail ?? monitor.snapshot.userID ?? "Unknown")
                usageRow("User budget duration", monitor.snapshot.userBudgetDuration ?? "Unknown")
                usageRow("RPM limit", monitor.snapshot.userRPM.map(String.init) ?? "Unknown")
                usageRow("TPM limit", monitor.snapshot.userTPM.map(String.init) ?? "Unknown")
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 12) {
                Text("API Key")
                    .font(.system(size: 16, weight: .bold, design: .rounded))

                usageRow("Alias", monitor.snapshot.keyAlias ?? "Unknown")
                usageRow("Name", monitor.snapshot.keyName ?? "Unknown")
                usageRow("Spend", CBORGFormatters.currency(monitor.snapshot.keySpend))
                usageRow("Last active", monitor.snapshot.keyLastActive ?? "Unknown")
                usageRow("Visible keys", String(monitor.snapshot.keyCount))
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))

            if let error = monitor.snapshot.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(12)
                    .background(.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
            }

            Spacer(minLength: 0)
        }
        .padding(24)
    }

    private func usageRow(_ label: String, _ value: String) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .font(.system(size: 13))
    }
}

private struct UsageMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let systemImage: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(color)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 26, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.58)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                Text(detail)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 142, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        }
    }
}
