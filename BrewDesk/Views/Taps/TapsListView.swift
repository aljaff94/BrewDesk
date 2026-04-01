import SwiftUI

struct TapsListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: TapsViewModel?

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    GenericSkeleton()
                } else if vm.taps.isEmpty {
                    ContentUnavailableView("No Taps", systemImage: "spigot", description: Text("No third-party taps installed."))
                } else {
                    List(vm.taps) { tap in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(tap.name)
                                        .fontWeight(.medium)
                                    if tap.official {
                                        Image(systemName: "checkmark.seal.fill")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                    }
                                }
                                if !tap.isLightweight {
                                    HStack(spacing: 12) {
                                        Label("\(tap.formulaCount) formulae", systemImage: "terminal")
                                        Label("\(tap.caskCount) casks", systemImage: "macwindow")
                                        if let lastCommit = tap.lastCommit {
                                            Text("Updated \(lastCommit)")
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                } else {
                                    Text(tap.user.isEmpty ? "" : "by \(tap.user)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if !tap.official {
                                Button(role: .destructive) {
                                    Task { await vm.removeTap(tap.name) }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            } else {
                GenericSkeleton()
            }
        }
        .navigationTitle("Taps")
        .toolbar {
            ToolbarItem {
                Button {
                    viewModel?.showAddTap = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem {
                Button {
                    Task { await viewModel?.load(forceRefresh: true) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel?.showAddTap ?? false },
            set: { viewModel?.showAddTap = $0 }
        )) {
            AddTapSheet()
                .environment(appState)
        }
        .task {
            let vm = TapsViewModel(client: appState.brewClient, cache: appState.cache)
            viewModel = vm
            await vm.load()
        }
    }
}
