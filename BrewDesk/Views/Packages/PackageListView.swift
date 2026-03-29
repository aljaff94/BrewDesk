import SwiftUI
import AppKit

struct PackageListView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModel: PackageListViewModel?
    @State private var selectedPackage: Package?
    @State private var showBulkConfirm = false
    @State private var bulkAction: BulkAction = .upgrade

    enum BulkAction { case upgrade, uninstall }

    let typeFilter: PackageType?
    var defaultFilter: PackageFilter = .all

    var body: some View {
        Group {
            if let vm = viewModel {
                if vm.isLoading {
                    PackageListSkeleton()
                } else if let error = vm.error {
                    ContentUnavailableView {
                        Label("Error", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("Retry") { Task { await vm.load() } }
                    }
                } else if vm.filteredPackages.isEmpty && !vm.searchText.isEmpty {
                    ContentUnavailableView {
                        Label(vm.isSearchingOnline ? "Searching..." : "No Results", systemImage: "magnifyingglass")
                    } description: {
                        if vm.isSearchingOnline {
                            Text("Searching Homebrew for \"\(vm.searchText)\"...")
                        } else {
                            Text("No packages found for \"\(vm.searchText)\"")
                        }
                    }
                } else {
                    List(vm.filteredPackages) { pkg in
                        PackageRow(
                            package: pkg,
                            showTypeBadge: typeFilter == nil,
                            isSelected: vm.selectedPackages.contains(pkg.id),
                            appState: appState
                        ) {
                            selectedPackage = pkg
                        } onInstall: { version in
                            Task {
                                let installName = version ?? pkg.name
                                await appState.runOperation(
                                    title: "Installing \(installName)",
                                    stream: appState.brewClient.install(installName, isCask: pkg.packageType == .cask)
                                )
                                await vm.load()
                            }
                        } onUpgrade: {
                            Task {
                                await appState.runOperation(
                                    title: "Upgrading \(pkg.name)",
                                    stream: appState.brewClient.upgrade(pkg.name)
                                )
                                await vm.load()
                                await appState.refreshOutdatedCount()
                            }
                        } onToggleSelect: {
                            vm.toggleSelection(pkg)
                        }
                        .contextMenu {
                            packageContextMenu(pkg)
                        }
                    }
                    .listStyle(.inset(alternatesRowBackgrounds: true))
                }
            } else {
                PackageListSkeleton()
            }
        }
        .navigationTitle(navigationTitle)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if let vm = viewModel {
                    PackageToolbar(
                        viewModel: vm,
                        appState: appState,
                        defaultFilter: defaultFilter
                    ) {
                        await upgradeAll()
                    } onBulkUpgrade: {
                        bulkAction = .upgrade
                        showBulkConfirm = true
                    } onBulkUninstall: {
                        bulkAction = .uninstall
                        showBulkConfirm = true
                    }
                }
            }
        }
        .task {
            let vm = PackageListViewModel(client: appState.brewClient)
            vm.selectedType = typeFilter
            vm.selectedFilter = defaultFilter
            vm.searchText = appState.globalSearchText
            viewModel = vm
            await vm.load()
            if !appState.globalSearchText.isEmpty {
                vm.triggerOnlineSearch()
            }
        }
        .onChange(of: appState.globalSearchText) { _, newValue in
            guard let vm = viewModel else { return }
            vm.searchText = newValue
            vm.triggerOnlineSearch()
        }
        .onKeyPress(.delete) {
            guard let vm = viewModel, vm.hasSelection else { return .ignored }
            bulkAction = .uninstall
            showBulkConfirm = true
            return .handled
        }
        .sheet(item: $selectedPackage) { pkg in
            PackageDetailView(package: pkg)
                .environment(appState)
                .frame(minWidth: 500, minHeight: 400)
        }
        .alert(bulkAlertTitle, isPresented: $showBulkConfirm) {
            Button("Cancel", role: .cancel) {}
            Button(bulkAction == .upgrade ? "Upgrade" : "Uninstall", role: bulkAction == .uninstall ? .destructive : nil) {
                Task { await performBulkAction() }
            }
        } message: {
            Text(bulkAlertMessage)
        }
    }

    private var navigationTitle: String {
        if let typeFilter {
            return typeFilter.rawValue
        }
        if defaultFilter == .outdated {
            return "Outdated"
        }
        return "All Packages"
    }

    private var bulkAlertTitle: String {
        guard let vm = viewModel else { return "" }
        let count = bulkAction == .upgrade ? vm.selectedOutdatedPackages.count : vm.selectedInstalledPackages.count
        return "\(bulkAction == .upgrade ? "Upgrade" : "Uninstall") \(count) package\(count == 1 ? "" : "s")?"
    }

    private var bulkAlertMessage: String {
        guard let vm = viewModel else { return "" }
        let packages = bulkAction == .upgrade ? vm.selectedOutdatedPackages : vm.selectedInstalledPackages
        let names = packages.prefix(5).map(\.name).joined(separator: ", ")
        let remaining = packages.count - 5
        return remaining > 0 ? "\(names), and \(remaining) more" : names
    }

    private func performBulkAction() async {
        guard let vm = viewModel else { return }
        let packages = bulkAction == .upgrade ? vm.selectedOutdatedPackages : vm.selectedInstalledPackages
        for pkg in packages {
            if bulkAction == .upgrade {
                await appState.runOperation(
                    title: "Upgrading \(pkg.name)",
                    stream: appState.brewClient.upgrade(pkg.name)
                )
            } else {
                await appState.runOperation(
                    title: "Uninstalling \(pkg.name)",
                    stream: appState.brewClient.uninstall(pkg.name, isCask: pkg.packageType == .cask)
                )
            }
        }
        vm.clearSelection()
        await vm.load()
    }

    private func upgradeAll() async {
        await appState.runOperation(
            title: "Upgrading All Packages",
            stream: appState.brewClient.upgrade(nil)
        )
        await viewModel?.load()
        await appState.refreshOutdatedCount()
    }

    @ViewBuilder
    private func packageContextMenu(_ pkg: Package) -> some View {
        if pkg.isInstalled {
            if pkg.isOutdated {
                Button("Upgrade") {
                    Task {
                        await appState.runOperation(
                            title: "Upgrading \(pkg.name)",
                            stream: appState.brewClient.upgrade(pkg.name)
                        )
                        await viewModel?.load()
                    }
                }
            }

            if case .cask = pkg, let appURL = caskAppURL(pkg.name) {
                Button("Open App") {
                    NSWorkspace.shared.open(appURL)
                }
            }

            Button("Uninstall", role: .destructive) {
                Task {
                    await appState.runOperation(
                        title: "Uninstalling \(pkg.name)",
                        stream: appState.brewClient.uninstall(pkg.name, isCask: pkg.packageType == .cask)
                    )
                    await viewModel?.load()
                }
            }
        } else {
            Button("Install") {
                Task {
                    await appState.runOperation(
                        title: "Installing \(pkg.name)",
                        stream: appState.brewClient.install(pkg.name, isCask: pkg.packageType == .cask)
                    )
                    await viewModel?.load()
                }
            }
        }
    }
}

// MARK: - Helpers

private func caskAppURL(_ caskName: String) -> URL? {
    // Try common app name patterns in /Applications
    let appName = caskName
        .split(separator: "-")
        .map { $0.prefix(1).uppercased() + $0.dropFirst() }
        .joined()
    let candidates = [
        "/Applications/\(appName).app",
        "/Applications/\(caskName).app",
    ]
    for path in candidates {
        if FileManager.default.fileExists(atPath: path) {
            return URL(fileURLWithPath: path)
        }
    }
    // Search /Applications for any .app containing the cask name
    let appsDir = URL(fileURLWithPath: "/Applications")
    if let apps = try? FileManager.default.contentsOfDirectory(at: appsDir, includingPropertiesForKeys: nil) {
        let match = apps.first { url in
            url.pathExtension == "app" &&
            url.deletingPathExtension().lastPathComponent
                .lowercased()
                .replacingOccurrences(of: " ", with: "")
                .contains(caskName.replacingOccurrences(of: "-", with: ""))
        }
        if let match { return match }
    }
    return nil
}

// MARK: - Toolbar

struct PackageToolbar: View {
    @Bindable var viewModel: PackageListViewModel
    let appState: AppState
    let defaultFilter: PackageFilter
    let onUpgradeAll: () async -> Void
    let onBulkUpgrade: () -> Void
    let onBulkUninstall: () -> Void

    var body: some View {
        Picker("Filter", selection: $viewModel.selectedFilter) {
            ForEach(PackageFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 280)

        Picker("Sort", selection: $viewModel.sortOrder) {
            ForEach(PackageListViewModel.SortOrder.allCases, id: \.self) { order in
                Text(order.rawValue).tag(order)
            }
        }
        .frame(width: 120)

        if viewModel.isSearchingOnline {
            ProgressView()
                .controlSize(.small)
        }

        if defaultFilter == .outdated {
            Button {
                Task { await onUpgradeAll() }
            } label: {
                Label("Upgrade All", systemImage: "arrow.up.circle.fill")
            }
            .disabled(appState.isOperationRunning)
        }

        if viewModel.hasSelection {
            Divider()

            if !viewModel.selectedOutdatedPackages.isEmpty {
                Button {
                    onBulkUpgrade()
                } label: {
                    Label("Upgrade (\(viewModel.selectedOutdatedPackages.count))", systemImage: "arrow.up.circle")
                }
                .disabled(appState.isOperationRunning)
            }

            Button(role: .destructive) {
                onBulkUninstall()
            } label: {
                Label("Uninstall (\(viewModel.selectedInstalledPackages.count))", systemImage: "trash")
            }
            .disabled(appState.isOperationRunning || viewModel.selectedInstalledPackages.isEmpty)

            Button {
                viewModel.clearSelection()
            } label: {
                Label("Deselect", systemImage: "xmark.circle")
            }
        }

        Text("\(viewModel.filteredPackages.count)")
            .font(.caption)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.quaternary)
            .clipShape(Capsule())
            .foregroundStyle(.secondary)
    }
}

// MARK: - Package Row

struct PackageRow: View {
    let package: Package
    let showTypeBadge: Bool
    let isSelected: Bool
    let appState: AppState
    let onSelect: () -> Void
    let onInstall: (_ version: String?) -> Void
    let onUpgrade: () -> Void
    let onToggleSelect: () -> Void

    @State private var selectedVersion: String = ""

    var body: some View {
        HStack(spacing: 10) {
            // Checkbox for installed packages
            if package.isInstalled {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14))
                    .foregroundStyle(isSelected ? Color.accentColor : Color.secondary.opacity(0.3))
                    .onTapGesture { onToggleSelect() }
            }

            // Icon
            Image(systemName: package.packageType == .formula ? "terminal" : "macwindow")
                .font(.system(size: 14))
                .foregroundStyle(package.isInstalled ? .primary : .tertiary)
                .frame(width: 22)

            // Name + description
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(package.displayName)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    if showTypeBadge {
                        Text(package.packageType.rawValue)
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .foregroundStyle(.secondary)
                            .background(.quaternary)
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                if let desc = package.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if package.isInstalled {
                // Version
                Text(package.installedVersion ?? package.latestVersion ?? "")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(package.isOutdated ? .orange : .secondary)

                // Inline upgrade button for outdated
                if package.isOutdated {
                    Button {
                        onUpgrade()
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.orange)
                    .disabled(appState.isOperationRunning)
                    .help("Upgrade to \(package.latestVersion ?? "latest")")
                }

                // Open button for cask apps
                if case .cask = package, let appURL = caskAppURL(package.name) {
                    Button {
                        NSWorkspace.shared.open(appURL)
                    } label: {
                        Image(systemName: "arrow.up.forward.app")
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Open \(package.displayName)")
                }

                // Status indicator
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 7, height: 7)
                    Text(statusText)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                }
                .frame(width: 75, alignment: .leading)
            } else {
                if let version = package.latestVersion {
                    Text(version)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                if !versionedFormulae.isEmpty {
                    Picker("", selection: $selectedVersion) {
                        Text("Latest").tag("")
                        ForEach(versionedFormulae, id: \.self) { v in
                            Text(v).tag(v)
                        }
                    }
                    .frame(width: 110)
                    .controlSize(.small)
                }

                Button {
                    onInstall(selectedVersion.isEmpty ? nil : selectedVersion)
                } label: {
                    Text("Install")
                        .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(.accentColor)
                .disabled(appState.isOperationRunning)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }

    private var versionedFormulae: [String] {
        if case .formula(let f) = package {
            return f.versionedFormulae
        }
        return []
    }

    private var statusColor: Color {
        if package.isOutdated { return .orange }
        if package.isInstalled { return .green }
        return .gray.opacity(0.5)
    }

    private var statusText: String {
        if package.isOutdated { return "Outdated" }
        if package.isInstalled { return "Installed" }
        return "Available"
    }
}
