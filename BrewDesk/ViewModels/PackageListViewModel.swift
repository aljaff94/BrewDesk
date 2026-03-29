import Foundation

@Observable
@MainActor
final class PackageListViewModel {
    var packages: [Package] = []
    var onlinePackages: [Package] = []
    var filteredPackages: [Package] = []
    var selectedPackages: Set<String> = []
    var isLoading = true
    var isSearchingOnline = false
    var error: BrewError?
    var searchText = "" {
        didSet {
            if searchText.isEmpty {
                onlinePackages = []
                searchTask?.cancel()
            }
            applyFilters()
        }
    }
    var selectedFilter: PackageFilter = .all { didSet { applyFilters() } }
    var selectedType: PackageType? = nil { didSet { applyFilters() } }
    var sortOrder: SortOrder = .name { didSet { applyFilters() } }

    enum SortOrder: String, CaseIterable, Sendable {
        case name = "Name"
        case type = "Type"
        case status = "Status"
        case installDate = "Install Date"
    }

    let client: any BrewClient
    private var searchTask: Task<Void, Never>?

    init(client: any BrewClient) {
        self.client = client
    }

    func load() async {
        isLoading = true
        error = nil

        do {
            let info = try await client.installedPackages()
            var all: [Package] = []
            all.append(contentsOf: info.formulae.map { .formula($0) })
            all.append(contentsOf: info.casks.map { .cask($0) })
            packages = all
            applyFilters()
        } catch let e as BrewError {
            error = e
        } catch {
            self.error = .decodingFailed(error.localizedDescription)
        }

        isLoading = false
    }

    func triggerOnlineSearch() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return }

        searchTask?.cancel()
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            await searchOnline(query: query)
        }
    }

    private func searchOnline(query: String) async {
        isSearchingOnline = true
        applyFilters()

        do {
            let results = try await client.search(query)
            guard !Task.isCancelled else {
                isSearchingOnline = false
                return
            }
            let names = results.prefix(30).map(\.name)
            guard !names.isEmpty else {
                onlinePackages = []
                isSearchingOnline = false
                applyFilters()
                return
            }

            let info = try await client.searchPackagesInfo(Array(names))
            guard !Task.isCancelled else {
                isSearchingOnline = false
                return
            }
            var found: [Package] = []
            found.append(contentsOf: info.formulae.map { .formula($0) })
            found.append(contentsOf: info.casks.map { .cask($0) })
            onlinePackages = found
        } catch {
            // Keep whatever we had before — don't clear on failure
        }

        isSearchingOnline = false
        applyFilters()
    }

    // MARK: - Bulk Operations

    var hasSelection: Bool { !selectedPackages.isEmpty }

    var selectedCount: Int { selectedPackages.count }

    func toggleSelection(_ package: Package) {
        if selectedPackages.contains(package.id) {
            selectedPackages.remove(package.id)
        } else {
            selectedPackages.insert(package.id)
        }
    }

    func selectAllFiltered() {
        for pkg in filteredPackages where pkg.isInstalled {
            selectedPackages.insert(pkg.id)
        }
    }

    func clearSelection() {
        selectedPackages.removeAll()
    }

    var selectedInstalledPackages: [Package] {
        filteredPackages.filter { selectedPackages.contains($0.id) && $0.isInstalled }
    }

    var selectedOutdatedPackages: [Package] {
        filteredPackages.filter { selectedPackages.contains($0.id) && $0.isOutdated }
    }

    // MARK: - Filters

    func applyFilters() {
        var result: [Package]

        if !searchText.isEmpty && !onlinePackages.isEmpty {
            // When we have online results: filter installed by search text, keep all online as-is
            let onlineIds = Set(onlinePackages.map(\.id))
            let matchingInstalled = packages.filter { pkg in
                // Only include installed packages that match the search text
                (pkg.name.localizedCaseInsensitiveContains(searchText) ||
                 (pkg.description?.localizedCaseInsensitiveContains(searchText) ?? false))
                && !onlineIds.contains(pkg.id)
            }
            // Online results that are also installed — prefer the installed version
            let installedIds = Set(packages.map(\.id))
            let onlineInstalledMatches = onlinePackages.filter { installedIds.contains($0.id) }
                .compactMap { online in packages.first { $0.id == online.id } }
            let pureOnline = onlinePackages.filter { !installedIds.contains($0.id) }
            result = matchingInstalled + onlineInstalledMatches + pureOnline
        } else if !searchText.isEmpty {
            // No online results yet — filter installed packages by search text
            result = packages.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        } else {
            result = packages
        }

        // Type filter
        if let selectedType {
            result = result.filter { $0.packageType == selectedType }
        }

        // Status filter
        switch selectedFilter {
        case .all: break
        case .installed: result = result.filter { $0.isInstalled }
        case .notInstalled: result = result.filter { !$0.isInstalled }
        case .outdated: result = result.filter { $0.isOutdated }
        }

        // Sort — installed packages always first, then by selected sort
        result.sort { lhs, rhs in
            if lhs.isInstalled != rhs.isInstalled {
                return lhs.isInstalled
            }
            switch sortOrder {
            case .name:
                return lhs.name.localizedCompare(rhs.name) == .orderedAscending
            case .type:
                return lhs.packageType.rawValue < rhs.packageType.rawValue
            case .status:
                if lhs.isOutdated != rhs.isOutdated { return lhs.isOutdated }
                return lhs.name < rhs.name
            case .installDate:
                let lDate = lhs.installDate ?? .distantPast
                let rDate = rhs.installDate ?? .distantPast
                return lDate > rDate // newest first
            }
        }

        filteredPackages = result
    }
}
