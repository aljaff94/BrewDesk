import Foundation

@Observable
@MainActor
final class ServicesViewModel {
    var services: [BrewServiceInfo] = []
    var isLoading = true
    var error: BrewError?

    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    func load() async {
        isLoading = true
        error = nil

        do {
            services = try await client.servicesList()
        } catch let e as BrewError {
            error = e
        } catch {}

        isLoading = false
    }

    func start(_ name: String) async {
        do {
            try await client.serviceStart(name)
            await load()
        } catch {}
    }

    func stop(_ name: String) async {
        do {
            try await client.serviceStop(name)
            await load()
        } catch {}
    }

    func restart(_ name: String) async {
        do {
            try await client.serviceRestart(name)
            await load()
        } catch {}
    }
}
