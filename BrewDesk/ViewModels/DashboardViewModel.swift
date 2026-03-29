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

    var totalInstalled: Int { formulaeCount + casksCount }
    var totalOutdated: Int { outdatedFormulaeCount + outdatedCasksCount }

    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    func load() async {
        isLoading = true
        error = nil

        async let infoTask: () = loadInstalled()
        async let outdatedTask: () = loadOutdated()
        async let versionTask: () = loadVersion()
        async let diskTask: () = loadDiskUsage()

        _ = await (infoTask, outdatedTask, versionTask, diskTask)

        isLoading = false
    }

    private func loadInstalled() async {
        do {
            let info = try await client.installedPackages()
            formulaeCount = info.formulae.count
            casksCount = info.casks.count
        } catch let e as BrewError {
            error = e
        } catch {}
    }

    private func loadOutdated() async {
        do {
            let outdated = try await client.outdatedPackages()
            outdatedFormulaeCount = outdated.formulae.count
            outdatedCasksCount = outdated.casks.count
        } catch {}
    }

    private func loadVersion() async {
        do {
            brewVersion = try await client.brewVersion()
        } catch {}
    }

    private func loadDiskUsage() async {
        diskUsage = await DiskUsageCalculator.calculateBrewDiskUsage()
        cacheUsage = await DiskUsageCalculator.cacheSize()
    }
}
