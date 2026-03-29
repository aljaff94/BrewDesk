import SwiftUI

struct DashboardView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 24) {
                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Formulae",
                            value: "\(vm.formulaeCount)",
                            icon: "terminal",
                            color: .blue
                        )
                        StatCard(
                            title: "Casks",
                            value: "\(vm.casksCount)",
                            icon: "macwindow",
                            color: .purple
                        )
                        StatCard(
                            title: "Outdated",
                            value: "\(vm.totalOutdated)",
                            icon: "arrow.triangle.2.circlepath",
                            color: vm.totalOutdated > 0 ? .orange : .green
                        )
                        StatCard(
                            title: "Disk Usage",
                            value: vm.diskUsage,
                            icon: "internaldrive",
                            color: .gray
                        )
                    }

                    // Quick actions
                    GroupBox("Quick Actions") {
                        HStack(spacing: 12) {
                            quickActionButton("Update Homebrew", icon: "arrow.clockwise", color: .blue) {
                                await appState.runOperation(title: "Updating Homebrew", stream: appState.brewClient.update())
                                await vm.load()
                            }

                            quickActionButton("Upgrade All", icon: "arrow.up.circle", color: .green) {
                                await appState.runOperation(title: "Upgrading All Packages", stream: appState.brewClient.upgrade(nil))
                                await vm.load()
                            }

                            quickActionButton("Cleanup", icon: "trash", color: .orange) {
                                await appState.runOperation(title: "Cleaning Up", stream: appState.brewClient.cleanup(dryRun: false))
                                await vm.load()
                            }

                            quickActionButton("Run Doctor", icon: "stethoscope", color: .red) {
                                await appState.runOperation(title: "Running Doctor", stream: appState.brewClient.doctor())
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                    }

                    // Recent operations
                    if !appState.operationHistory.isEmpty {
                        GroupBox("Recent Operations") {
                            VStack(spacing: 0) {
                                ForEach(appState.operationHistory.prefix(5)) { record in
                                    HStack(spacing: 8) {
                                        Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                            .foregroundStyle(record.success ? .green : .red)
                                            .font(.system(size: 12))
                                        Text(record.title)
                                            .lineLimit(1)
                                        Spacer()
                                        Text(record.timestamp, style: .relative)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    if record.id != appState.operationHistory.prefix(5).last?.id {
                                        Divider()
                                    }
                                }
                                if appState.operationHistory.count > 5 {
                                    Button("View All History...") {
                                        appState.showOperationHistory = true
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(Color.accentColor)
                                    .padding(.top, 6)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Info section
                    if !vm.brewVersion.isEmpty {
                        GroupBox("Info") {
                            VStack(alignment: .leading, spacing: 8) {
                                infoRow("Homebrew Version", value: vm.brewVersion)
                                infoRow("Cache Size", value: vm.cacheUsage)
                                infoRow("Total Installed", value: "\(vm.totalInstalled) packages")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .padding(24)
                .overlay {
                    if vm.isLoading {
                        DashboardSkeleton()
                            .background(.ultraThinMaterial)
                    }
                }
            } else {
                DashboardSkeleton()
            }
        }
        .navigationTitle("Dashboard")
        .task {
            let vm = DashboardViewModel(client: appState.brewClient)
            viewModel = vm
            await vm.load()
        }
        .refreshable {
            await viewModel?.load()
        }
    }

    private func quickActionButton(_ title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task { await action() }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(width: 100, height: 60)
        }
        .buttonStyle(.bordered)
        .tint(color)
        .disabled(appState.isOperationRunning)
    }

    private func infoRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
