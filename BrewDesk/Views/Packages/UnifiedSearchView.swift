import SwiftUI
import AppKit

struct UnifiedSearchView: View {
    @Environment(AppState.self) private var appState
    @State private var installedPackages: [Package] = []
    @State private var onlinePackages: [Package] = []
    @State private var isSearchingOnline = false
    @State private var selectedPackage: Package?
    @State private var hasLoaded = false
    private var searchTask: Task<Void, Never>?

    var body: some View {
        Group {
            if filteredSections.isEmpty && !isSearchingOnline {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("No packages found for \"\(appState.globalSearchText)\"")
                }
            } else {
                List {
                    ForEach(filteredSections, id: \.title) { section in
                        Section {
                            ForEach(section.packages) { pkg in
                                searchRow(pkg)
                            }
                        } header: {
                            HStack {
                                Label(section.title, systemImage: section.icon)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(section.color)
                                Spacer()
                                Text("\(section.packages.count)")
                                    .font(.caption2.weight(.medium))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 1)
                                    .background(section.color.opacity(0.12))
                                    .foregroundStyle(section.color)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    if isSearchingOnline {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Searching Homebrew online...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("Search Results")
        .task(id: appState.globalSearchText) {
            await performSearch()
        }
        .task {
            if !hasLoaded {
                await loadInstalledPackages()
                hasLoaded = true
            }
        }
        .sheet(item: $selectedPackage) { pkg in
            PackageDetailView(package: pkg)
                .environment(appState)
                .frame(minWidth: 500, minHeight: 400)
        }
    }

    // MARK: - Sections

    private struct SearchSection {
        let title: String
        let icon: String
        let color: Color
        let packages: [Package]
    }

    private var filteredSections: [SearchSection] {
        let query = appState.globalSearchText.lowercased()
        guard !query.isEmpty else { return [] }

        let installedIds = Set(installedPackages.map(\.id))

        // Installed Formulae
        let installedFormulae = installedPackages.filter { pkg in
            pkg.packageType == .formula && matchesQuery(pkg, query)
        }
        // Installed Casks
        let installedCasks = installedPackages.filter { pkg in
            pkg.packageType == .cask && matchesQuery(pkg, query)
        }
        // Online Formulae (not already installed)
        let onlineFormulae = onlinePackages.filter { pkg in
            pkg.packageType == .formula && !installedIds.contains(pkg.id)
        }
        // Online Casks (not already installed)
        let onlineCasks = onlinePackages.filter { pkg in
            pkg.packageType == .cask && !installedIds.contains(pkg.id)
        }

        var sections: [SearchSection] = []
        if !installedFormulae.isEmpty {
            sections.append(SearchSection(title: "Installed Formulae", icon: "terminal", color: .blue, packages: installedFormulae))
        }
        if !installedCasks.isEmpty {
            sections.append(SearchSection(title: "Installed Casks", icon: "macwindow", color: .purple, packages: installedCasks))
        }
        if !onlineFormulae.isEmpty {
            sections.append(SearchSection(title: "Available Formulae", icon: "terminal", color: .secondary, packages: onlineFormulae))
        }
        if !onlineCasks.isEmpty {
            sections.append(SearchSection(title: "Available Casks", icon: "macwindow", color: .secondary, packages: onlineCasks))
        }
        return sections
    }

    private func matchesQuery(_ pkg: Package, _ query: String) -> Bool {
        pkg.name.localizedCaseInsensitiveContains(query) ||
        (pkg.description?.localizedCaseInsensitiveContains(query) ?? false)
    }

    // MARK: - Search Logic

    private func loadInstalledPackages() async {
        do {
            let info = try await appState.cache.getInstalledPackages()
            var all: [Package] = []
            all.append(contentsOf: info.formulae.map { .formula($0) })
            all.append(contentsOf: info.casks.map { .cask($0) })
            installedPackages = all
        } catch {}
    }

    private func performSearch() async {
        let query = appState.globalSearchText.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            onlinePackages = []
            isSearchingOnline = false
            return
        }

        // Debounce
        try? await Task.sleep(for: .milliseconds(350))
        guard !Task.isCancelled else { return }

        isSearchingOnline = true

        do {
            let results = try await appState.brewClient.search(query)
            guard !Task.isCancelled else { return }

            let names = results.prefix(30).map(\.name)
            guard !names.isEmpty else {
                onlinePackages = []
                isSearchingOnline = false
                return
            }

            let info = try await appState.brewClient.searchPackagesInfo(Array(names))
            guard !Task.isCancelled else { return }

            var found: [Package] = []
            found.append(contentsOf: info.formulae.map { .formula($0) })
            found.append(contentsOf: info.casks.map { .cask($0) })
            onlinePackages = found
        } catch {
            if !Task.isCancelled {
                onlinePackages = []
            }
        }

        if !Task.isCancelled {
            isSearchingOnline = false
        }
    }

    // MARK: - Row View

    private func searchRow(_ pkg: Package) -> some View {
        HStack(spacing: 10) {
            Image(systemName: pkg.packageType == .formula ? "terminal" : "macwindow")
                .font(.system(size: 13))
                .foregroundStyle(pkg.isInstalled ? .primary : .tertiary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 6) {
                    Text(pkg.displayName)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if pkg.isOutdated {
                        Text("Outdated")
                            .font(.system(size: 9, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .foregroundStyle(.orange)
                            .background(.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
                if let desc = pkg.description {
                    Text(desc)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if pkg.isInstalled {
                Text(pkg.installedVersion ?? "")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.secondary)

                HStack(spacing: 4) {
                    Circle()
                        .fill(pkg.isOutdated ? Color.orange : Color.green)
                        .frame(width: 6, height: 6)
                    Text(pkg.isOutdated ? "Outdated" : "Installed")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            } else {
                if let version = pkg.latestVersion {
                    Text(version)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Button {
                    Task {
                        await appState.runOperation(
                            title: "Installing \(pkg.name)",
                            stream: appState.brewClient.install(pkg.name, isCask: pkg.packageType == .cask)
                        )
                        appState.cache.invalidatePackages()
                        await loadInstalledPackages()
                    }
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
            selectedPackage = pkg
        }
    }
}
