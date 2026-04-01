import Foundation

@Observable
@MainActor
final class ServicesViewModel {
    var services: [BrewServiceInfo] = []
    var isLoading = true
    var error: BrewError?

    private let client: any BrewClient
    private let cache: BrewCache

    init(client: any BrewClient, cache: BrewCache) {
        self.client = client
        self.cache = cache
    }

    func load(forceRefresh: Bool = false) async {
        // If cache has data, show instantly
        let hasCachedData = cache.services != nil
        if !hasCachedData {
            isLoading = true
        }
        error = nil

        do {
            services = try await cache.getServices(forceRefresh: forceRefresh)
        } catch let e as BrewError {
            error = e
        } catch {}

        isLoading = false
    }

    func start(_ name: String) async {
        do {
            try await client.serviceStart(name)
            cache.invalidateServices()
            await refreshServiceStatus(name)
        } catch {}
    }

    func stop(_ name: String) async {
        do {
            try await client.serviceStop(name)
            cache.invalidateServices()
            await refreshServiceStatus(name)
        } catch {}
    }

    func restart(_ name: String) async {
        do {
            try await client.serviceRestart(name)
            cache.invalidateServices()
            await refreshServiceStatus(name)
        } catch {}
    }

    private func refreshServiceStatus(_ name: String) async {
        do {
            let updatedServices = try await cache.getServices(forceRefresh: true)
            services = updatedServices
        } catch {}
    }
}
