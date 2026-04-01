import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .frame(minWidth: 200)
        } detail: {
            if !appState.globalSearchText.isEmpty {
                UnifiedSearchView()
            } else {
                detailView
            }
        }
        .searchable(
            text: Binding(
                get: { appState.globalSearchText },
                set: { appState.globalSearchText = $0 }
            ),
            placement: .toolbar,
            prompt: "Search packages..."
        )
        .sheet(isPresented: Binding(
            get: { appState.showOperationSheet },
            set: { appState.showOperationSheet = $0 }
        )) {
            OperationSheet()
                .environment(appState)
        }
        .sheet(isPresented: Binding(
            get: { appState.showOperationHistory },
            set: { appState.showOperationHistory = $0 }
        )) {
            OperationHistoryView()
                .environment(appState)
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSidebar {
        case .dashboard, nil:
            DashboardView()
        case .formulae:
            PackageListView(typeFilter: .formula)
        case .casks:
            PackageListView(typeFilter: .cask)
        case .outdated:
            PackageListView(typeFilter: nil, defaultFilter: .outdated)
        case .services:
            ServicesListView()
        case .taps:
            TapsListView()
        case .dependencies:
            DependencyTreeView()
        case .maintenance:
            MaintenanceView()
        case .brewfile:
            BrewfileView()
        }
    }
}
