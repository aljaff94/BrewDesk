import Foundation

@Observable
@MainActor
final class TapsViewModel {
    var taps: [Tap] = []
    var isLoading = true
    var error: BrewError?
    var showAddTap = false
    var newTapName = ""

    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    func load() async {
        isLoading = true
        error = nil

        do {
            taps = try await client.installedTaps()
        } catch let e as BrewError {
            error = e
        } catch {}

        isLoading = false
    }

    func addTapStream() -> AsyncThrowingStream<String, Error> {
        client.addTap(newTapName)
    }

    func removeTap(_ name: String) async {
        do {
            try await client.removeTap(name)
            await load()
        } catch {}
    }
}
