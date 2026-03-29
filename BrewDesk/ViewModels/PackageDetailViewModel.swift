import Foundation

@Observable
@MainActor
final class PackageDetailViewModel {
    var package: Package
    var isLoading = false
    var diskUsage: String?
    var reverseDeps: [String] = []
    var error: BrewError?

    private let client: any BrewClient

    init(package: Package, client: any BrewClient) {
        self.package = package
        self.client = client
    }

    func refresh() async {
        isLoading = true
        do {
            let info = try await client.packageInfo(package.name)
            if let formula = info.formulae.first {
                package = .formula(formula)
            } else if let cask = info.casks.first {
                package = .cask(cask)
            }
        } catch let e as BrewError {
            error = e
        } catch {}
        isLoading = false
    }

    func loadExtras() async {
        async let diskTask: () = loadDiskUsage()
        async let depsTask: () = loadReverseDeps()
        _ = await (diskTask, depsTask)
    }

    private func loadDiskUsage() async {
        guard package.isInstalled else { return }
        do {
            diskUsage = try await client.packageDiskUsage(
                package.name,
                isCask: package.packageType == .cask
            )
        } catch {
            diskUsage = nil
        }
    }

    private func loadReverseDeps() async {
        guard package.isInstalled, package.packageType == .formula else { return }
        do {
            reverseDeps = try await client.reverseDependencies(package.name)
        } catch {
            reverseDeps = []
        }
    }

    func installStream() -> AsyncThrowingStream<String, Error> {
        client.install(package.name, isCask: package.packageType == .cask)
    }

    func uninstallStream() -> AsyncThrowingStream<String, Error> {
        client.uninstall(package.name, isCask: package.packageType == .cask)
    }

    func upgradeStream() -> AsyncThrowingStream<String, Error> {
        client.upgrade(package.name)
    }

    func togglePin() async throws {
        guard case .formula(let formula) = package else { return }
        if formula.pinned {
            try await client.unpin(formula.name)
        } else {
            try await client.pin(formula.name)
        }
        await refresh()
    }
}
