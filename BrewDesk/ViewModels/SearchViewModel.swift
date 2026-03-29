import Foundation
import Combine

@Observable
@MainActor
final class SearchViewModel {
    var query = ""
    var results: [SearchResult] = []
    var isSearching = false

    private let client: any BrewClient
    private var searchTask: Task<Void, Never>?

    init(client: any BrewClient) {
        self.client = client
    }

    func search() {
        searchTask?.cancel()

        let currentQuery = query.trimmingCharacters(in: .whitespaces)
        guard currentQuery.count >= 2 else {
            results = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            // Debounce
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }

            do {
                let searchResults = try await client.search(currentQuery)
                if !Task.isCancelled {
                    results = searchResults
                }
            } catch {
                if !Task.isCancelled {
                    results = []
                }
            }

            if !Task.isCancelled {
                isSearching = false
            }
        }
    }
}
