import SwiftUI

struct ServicesListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: ServicesViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    ServiceListSkeleton()
                } else if vm.services.isEmpty {
                    ContentUnavailableView(
                        "No Services",
                        systemImage: "gearshape.2",
                        description: Text("No Homebrew services are configured.\nInstall a formula with a service (e.g., postgresql, redis) to see it here.")
                    )
                } else {
                    Table(vm.services) {
                        TableColumn("Name") { service in
                            Text(service.name)
                                .fontWeight(.medium)
                        }
                        .width(min: 150, ideal: 200)

                        TableColumn("Status") { service in
                            ServiceStatusBadge(status: service.statusDisplay)
                        }
                        .width(80)

                        TableColumn("User") { service in
                            Text(service.user ?? "-")
                                .foregroundStyle(.secondary)
                        }
                        .width(100)

                        TableColumn("PID") { service in
                            Text(service.pid.map(String.init) ?? "-")
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                        }
                        .width(80)

                        TableColumn("Actions") { service in
                            ServiceActionButtons(service: service, viewModel: vm)
                        }
                        .width(min: 150, ideal: 200)
                    }
                }
            } else {
                ServiceListSkeleton()
            }
        }
        .navigationTitle("Services")
        .toolbar {
            ToolbarItem {
                Button {
                    Task { await viewModel?.load() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            let vm = ServicesViewModel(client: appState.brewClient, cache: appState.cache)
            viewModel = vm
            await vm.load()
        }
    }
}

struct ServiceStatusBadge: View {
    let status: ServiceStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.rawValue)
                .font(.caption)
        }
    }

    private var color: Color {
        switch status {
        case .running: return .green
        case .stopped: return .gray
        case .error: return .red
        case .unknown: return .yellow
        }
    }
}

struct ServiceActionButtons: View {
    let service: BrewServiceInfo
    let viewModel: ServicesViewModel

    var body: some View {
        HStack(spacing: 4) {
            if service.isRunning {
                Button("Stop") { Task { await viewModel.stop(service.name) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                Button("Restart") { Task { await viewModel.restart(service.name) } }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            } else {
                Button("Start") { Task { await viewModel.start(service.name) } }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
    }
}
