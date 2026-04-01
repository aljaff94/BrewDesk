import Foundation

@Observable
@MainActor
final class DashboardViewModel {
    var formulaeCount = 0
    var casksCount = 0
    var outdatedFormulaeCount = 0
    var outdatedCasksCount = 0
    var diskUsage = "Calculating..."
    var cacheUsage = "Calculating..."
    var brewVersion = ""
    var isLoading = true
    var error: BrewError?

    // Enhanced data for redesigned dashboard
    var outdatedFormulae: [OutdatedFormula] = []
    var outdatedCasks: [OutdatedCask] = []
    var recentFormulae: [Formula] = []
    var recentCasks: [Cask] = []
    var pinnedCount = 0
    var deprecatedCount = 0
    var servicesCount = 0

    var totalInstalled: Int { formulaeCount + casksCount }
    var totalOutdated: Int { outdatedFormulaeCount + outdatedCasksCount }

    private let client: any BrewClient
    private let cache: BrewCache

    init(client: any BrewClient, cache: BrewCache) {
        self.client = client
        self.cache = cache
    }

    func load(forceRefresh: Bool = false) async {
        let hasCachedData = cache.installedPackages != nil && cache.outdatedPackages != nil
        if !hasCachedData {
            isLoading = true
        }
        error = nil

        // Show cached data immediately
        if let cached = cache.installedPackages {
            applyInstalledData(cached)
        }
        if let cached = cache.outdatedPackages {
            applyOutdatedData(cached)
        }
        if let cached = cache.brewVersion {
            brewVersion = cached
        }
        if let cached = cache.diskUsage {
            diskUsage = cached
        }
        if let cached = cache.cacheUsage {
            cacheUsage = cached
        }
        if let cached = cache.services {
            servicesCount = cached.filter(\.isRunning).count
        }

        if hasCachedData && !forceRefresh {
            isLoading = false
            return
        }

        async let infoTask: () = loadInstalled(forceRefresh: forceRefresh)
        async let outdatedTask: () = loadOutdated(forceRefresh: forceRefresh)
        async let versionTask: () = loadVersion(forceRefresh: forceRefresh)
        async let diskTask: () = loadDiskUsage(forceRefresh: forceRefresh)
        async let servicesTask: () = loadServices(forceRefresh: forceRefresh)

        _ = await (infoTask, outdatedTask, versionTask, diskTask, servicesTask)

        isLoading = false
    }

    private func applyInstalledData(_ info: BrewInfoResponse) {
        formulaeCount = info.formulae.count
        casksCount = info.casks.count
        pinnedCount = info.formulae.filter(\.pinned).count
        deprecatedCount = info.formulae.filter(\.deprecated).count + info.casks.filter(\.deprecated).count

        // Recent installs — sort by install time, take newest 5
        let sortedFormulae = info.formulae
            .filter(\.isInstalled)
            .sorted { ($0.installed.first?.time ?? 0) > ($1.installed.first?.time ?? 0) }
        recentFormulae = Array(sortedFormulae.prefix(5))

        let sortedCasks = info.casks
            .filter(\.isInstalled)
            .sorted { ($0.installedTime ?? 0) > ($1.installedTime ?? 0) }
        recentCasks = Array(sortedCasks.prefix(5))
    }

    private func applyOutdatedData(_ outdated: BrewOutdatedResponse) {
        outdatedFormulaeCount = outdated.formulae.count
        outdatedCasksCount = outdated.casks.count
        outdatedFormulae = Array(outdated.formulae.prefix(10))
        outdatedCasks = Array(outdated.casks.prefix(10))
    }

    private func loadInstalled(forceRefresh: Bool) async {
        do {
            let info = try await cache.getInstalledPackages(forceRefresh: forceRefresh)
            applyInstalledData(info)
        } catch let e as BrewError {
            error = e
        } catch {}
    }

    private func loadOutdated(forceRefresh: Bool) async {
        do {
            let outdated = try await cache.getOutdatedPackages(forceRefresh: forceRefresh)
            applyOutdatedData(outdated)
        } catch {}
    }

    private func loadVersion(forceRefresh: Bool) async {
        do {
            brewVersion = try await cache.getBrewVersion(forceRefresh: forceRefresh)
        } catch {}
    }

    private func loadDiskUsage(forceRefresh: Bool) async {
        diskUsage = await cache.getDiskUsage(forceRefresh: forceRefresh)
        cacheUsage = await cache.getCacheSize(forceRefresh: forceRefresh)
    }

    private func loadServices(forceRefresh: Bool) async {
        do {
            let svcs = try await cache.getServices(forceRefresh: forceRefresh)
            servicesCount = svcs.filter(\.isRunning).count
        } catch {}
    }
}
