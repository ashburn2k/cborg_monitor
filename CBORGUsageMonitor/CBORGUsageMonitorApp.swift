import AppKit
import SwiftUI

@main
struct CBORGUsageMonitorApp: App {
    @StateObject private var monitor = CBORGMonitorViewModel()

    var body: some Scene {
        MenuBarExtra {
            MenuBarPanel()
                .environmentObject(monitor)
        } label: {
            Label {
                Text(monitor.menuTitle)
            } icon: {
                Image(systemName: monitor.snapshot.health.symbolName)
            }
        }
        .menuBarExtraStyle(.window)

        WindowGroup("CBORG Usage", id: "dashboard") {
            ContentView()
                .environmentObject(monitor)
        }
        .windowResizability(.contentMinSize)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Refresh CBORG Usage") {
                    Task { await monitor.refresh() }
                }
                .keyboardShortcut("r", modifiers: [.command])
                .disabled(!monitor.canRefresh)
            }
        }
    }
}

private struct MenuBarPanel: View {
    @EnvironmentObject private var monitor: CBORGMonitorViewModel
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: 12) {
                panelContent
            }
        } else {
            panelContent
        }
    }

    private var panelContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: monitor.snapshot.health.symbolName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(monitor.snapshot.health.color)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CBORG Usage")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                    Text(monitor.snapshot.health.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(CBORGFormatters.percent(monitor.snapshot.displayPercent))
                        .font(.system(size: 34, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                    Text("of budget")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.secondary)
                }

                BudgetProgressBar(
                    percent: monitor.snapshot.displayPercent,
                    thresholdPercent: monitor.thresholdPercent,
                    color: monitor.snapshot.health.budgetMeterColor,
                    height: 8,
                    showsThreshold: false
                )

                VStack(alignment: .leading, spacing: 6) {
                    usageLine("Spend", CBORGFormatters.currency(monitor.snapshot.displaySpend))
                    usageLine("Budget", CBORGFormatters.currency(monitor.snapshot.displayBudget))
                    usageLine("Reset", CBORGFormatters.resetDate(monitor.snapshot.displayReset))
                    usageLine("Checked", CBORGFormatters.compactTime(monitor.snapshot.checkedAt))
                }
            }
            .padding(14)
            .cborgGlassSurface(cornerRadius: 18, tint: monitor.snapshot.health.color)

            if let error = monitor.snapshot.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .lineLimit(3)
                    .padding(10)
                    .cborgGlassSurface(cornerRadius: 14, tint: .orange)
            }

            HStack(spacing: 8) {
                Button {
                    Task { await monitor.refresh() }
                } label: {
                    if monitor.isRefreshing {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
                .cborgPrimaryActionStyle()
                .disabled(!monitor.canRefresh)

                Button {
                    openWindow(id: "dashboard")
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.capsule)
            }

            Divider()

            Button("Quit CBORG Usage") {
                NSApp.terminate(nil)
            }
            .font(.system(size: 12, weight: .medium))
        }
        .padding(16)
        .frame(width: 300)
    }

    private func usageLine(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .font(.system(size: 12))
    }
}
