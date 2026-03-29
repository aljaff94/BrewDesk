import Foundation

@Observable
@MainActor
final class BrewfileViewModel {
    var brewfileContent = ""
    var entries: [BrewfileEntry] = []
    var isLoading = false
    var error: BrewError?

    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    func exportBrewfile() async {
        isLoading = true
        error = nil

        do {
            brewfileContent = try await client.brewfileDump()
            entries = BrewfileParser.parse(brewfileContent)
        } catch let e as BrewError {
            error = e
        } catch {}

        isLoading = false
    }

    func installStream(from path: String) -> AsyncThrowingStream<String, Error> {
        client.brewfileInstall(from: path)
    }
}
