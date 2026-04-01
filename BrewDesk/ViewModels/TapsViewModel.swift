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
    private let cache: BrewCache

    init(client: any BrewClient, cache: BrewCache) {
        self.client = client
        self.cache = cache
    }

    func load(forceRefresh: Bool = false) async {
        // If we have cached full taps, use them instantly
        if !forceRefresh, let cached = cache.taps {
            taps = cached
            isLoading = false
            return
        }

        // If we have cached tap names, show lightweight taps instantly
        if !forceRefresh, let cachedNames = cache.tapNames {
            taps = cachedNames.map { Tap.fromName($0) }
            isLoading = false
            // Fetch full details in background
            Task {
                if let fullTaps = try? await cache.getTaps(forceRefresh: false) {
                    taps = fullTaps
                }
            }
            return
        }

        error = nil

        // Step 1: Fast load — `brew tap` returns in ~50ms
        do {
            let names = try await cache.getTapNames(forceRefresh: forceRefresh)
            taps = names.map { Tap.fromName($0) }
            isLoading = false
        } catch let e as BrewError {
            error = e
            isLoading = false
            return
        } catch {
            isLoading = false
            return
        }

        // Step 2: Fetch full details in background (non-blocking)
        do {
            let fullTaps = try await cache.getTaps(forceRefresh: forceRefresh)
            taps = fullTaps
        } catch {
            // Keep lightweight taps — they're still useful
        }
    }

    func addTapStream() -> AsyncThrowingStream<String, Error> {
        client.addTap(newTapName)
    }

    func removeTap(_ name: String) async {
        do {
            try await client.removeTap(name)
            // Remove immediately from local list for instant feedback
            taps.removeAll { $0.name == name }
            cache.invalidateTaps()
        } catch {}
    }
}
