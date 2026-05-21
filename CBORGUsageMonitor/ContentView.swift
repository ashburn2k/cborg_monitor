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
        .frame(minWidth: 860, minHeight: 500)
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
        .padding(20)
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

            BudgetProgressCard(snapshot: monitor.snapshot, thresholdPercent: monitor.thresholdPercent)

            HStack(alignment: .top, spacing: 14) {
                InfoCard(title: "Account") {
                    usageRow("Alias", monitor.snapshot.userAlias ?? "Unknown")
                    usageRow("Email", monitor.snapshot.userEmail ?? monitor.snapshot.userID ?? "Unknown")
                    usageRow("Cycle", monitor.snapshot.userBudgetDuration ?? "Unknown")
                    usageRow("RPM", monitor.snapshot.userRPM.map(String.init) ?? "Unknown")
                    usageRow("TPM", monitor.snapshot.userTPM.map(String.init) ?? "Unknown")
                }

                InfoCard(title: "API Key") {
                    usageRow("Alias", monitor.snapshot.keyAlias ?? "Unknown")
                    usageRow("Name", monitor.snapshot.keyName ?? "Unknown")
                    usageRow("Spend", CBORGFormatters.currency(monitor.snapshot.keySpend))
                    usageRow("Active", monitor.snapshot.keyLastActive ?? "Unknown")
                    usageRow("Keys", String(monitor.snapshot.keyCount))
                }
            }

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

private struct BudgetProgressCard: View {
    let snapshot: CBORGUsageSnapshot
    let thresholdPercent: Double

    private var remainingText: String {
        guard let spend = snapshot.displaySpend, let budget = snapshot.displayBudget else {
            return "Unknown"
        }
        return CBORGFormatters.currency(max(budget - spend, 0))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("Budget Progress", systemImage: "gauge.with.dots.needle.67percent")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(snapshot.health.color)
                    Text("Alert at \(CBORGFormatters.percent(thresholdPercent))")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(CBORGFormatters.percent(snapshot.displayPercent))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundStyle(snapshot.health.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            BudgetProgressBar(
                percent: snapshot.displayPercent,
                thresholdPercent: thresholdPercent,
                color: snapshot.health.color,
                height: 14,
                showsThreshold: true
            )

            HStack(spacing: 12) {
                ProgressStat(title: "Spent", value: CBORGFormatters.currency(snapshot.displaySpend), color: .green)
                ProgressStat(title: "Budget", value: CBORGFormatters.currency(snapshot.displayBudget), color: .blue)
                ProgressStat(title: "Remaining", value: remainingText, color: snapshot.health.color)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        }
    }
}

private struct ProgressStat: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(size: 16, weight: .black, design: .rounded))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.62)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InfoCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.system(size: 15, weight: .bold, design: .rounded))

            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.secondary.opacity(0.12), lineWidth: 1)
        }
    }
}

struct BudgetProgressBar: View {
    let percent: Double?
    let thresholdPercent: Double
    let color: Color
    let height: CGFloat
    let showsThreshold: Bool

    private var progress: Double {
        min(max((percent ?? 0) / 100, 0), 1)
    }

    private var threshold: Double {
        min(max(thresholdPercent / 100, 0), 1)
    }

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let progressWidth = progress > 0 ? min(width, max(width * progress, height)) : 0
            let thresholdX = min(max(width * threshold - 1, 0), max(width - 2, 0))

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.secondary.opacity(0.14))

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.78), color],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: progressWidth)

                if showsThreshold {
                    Rectangle()
                        .fill(Color.primary.opacity(0.45))
                        .frame(width: 2, height: height + 7)
                        .offset(x: thresholdX)
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityLabel("Budget usage")
        .accessibilityValue(CBORGFormatters.percent(percent))
    }
}
