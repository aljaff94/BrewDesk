import SwiftUI

struct MaintenanceView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: MaintenanceViewModel?

    var body: some View {
        ScrollView {
            if let vm = viewModel {
                VStack(spacing: 20) {
                    // Doctor section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Doctor", systemImage: "stethoscope")
                                    .font(.headline)
                                Spacer()
                                Button("Run Doctor") {
                                    Task { await vm.runDoctor() }
                                }
                                .buttonStyle(.bordered)
                                .disabled(vm.isRunningDoctor)
                            }

                            if vm.isRunningDoctor {
                                ProgressView("Running brew doctor...")
                            } else if vm.isDoctorDone {
                                if vm.doctorWarnings.isEmpty {
                                    Label("Your system is ready to brew.", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    ForEach(vm.doctorWarnings) { warning in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(warning.message)
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(.orange)
                                                .textSelection(.enabled)
                                        }
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                    }
                                }
                            }
                        }
                    }

                    // Cleanup section
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Cleanup", systemImage: "trash")
                                    .font(.headline)
                                Spacer()
                                if !vm.cacheSize.isEmpty {
                                    Text("Cache: \(vm.cacheSize)")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                Button("Preview") {
                                    Task { await vm.runCleanupDryRun() }
                                }
                                .buttonStyle(.bordered)
                                .disabled(vm.isRunningCleanup)

                                Button("Clean Now") {
                                    Task {
                                        await appState.runOperation(
                                            title: "Cleaning Up",
                                            stream: vm.cleanupStream()
                                        )
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .disabled(appState.isOperationRunning)
                            }

                            if vm.isRunningCleanup {
                                ProgressView("Scanning...")
                            } else if vm.isCleanupDone {
                                if vm.cleanupItems.isEmpty {
                                    Label("Nothing to clean up.", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    ForEach(vm.cleanupItems) { item in
                                        HStack {
                                            Text(item.path)
                                                .font(.system(.caption, design: .monospaced))
                                                .lineLimit(1)
                                                .truncationMode(.middle)
                                            Spacer()
                                            Text(item.size)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(24)
            } else {
                GenericSkeleton()
            }
        }
        .navigationTitle("Maintenance")
        .task {
            let vm = MaintenanceViewModel(client: appState.brewClient)
            viewModel = vm
            await vm.loadCacheSize()
        }
    }
}
