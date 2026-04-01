import SwiftUI

struct OperationRecord: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let timestamp: Date
    let output: [String]
    let success: Bool
}

// MARK: - Brew Data Cache

@Observable
@MainActor
final class BrewCache {
    var installedPackages: BrewInfoResponse?
    var outdatedPackages: BrewOutdatedResponse?
    var services: [BrewServiceInfo]?
    var taps: [Tap]?
    var tapNames: [String]?
    var brewVersion: String?
    var diskUsage: String?
    var cacheUsage: String?

    /// In-flight tasks — concurrent callers await the same task instead of getting empty data
    private var inFlight: [String: Task<Sendable, Error>] = [:]
    private let client: any BrewClient

    init(client: any BrewClient) {
        self.client = client
    }

    /// Fetch installed packages — returns cached if available, waits for in-flight fetch if one exists
    func getInstalledPackages(forceRefresh: Bool = false) async throws -> BrewInfoResponse {
        if !forceRefresh, let cached = installedPackages { return cached }
        if let existing = inFlight["installed"] {
            return try await existing.value as? BrewInfoResponse ?? BrewInfoResponse(formulae: [], casks: [])
        }
        let task = Task<Sendable, Error> {
            try await client.installedPackages()
        }
        inFlight["installed"] = task
        do {
            let result = try await task.value as! BrewInfoResponse
            installedPackages = result
            inFlight.removeValue(forKey: "installed")
            return result
        } catch {
            inFlight.removeValue(forKey: "installed")
            throw error
        }
    }

    /// Fetch outdated packages — returns cached if available, waits for in-flight fetch
    func getOutdatedPackages(forceRefresh: Bool = false) async throws -> BrewOutdatedResponse {
        if !forceRefresh, let cached = outdatedPackages { return cached }
        if let existing = inFlight["outdated"] {
            return try await existing.value as? BrewOutdatedResponse ?? BrewOutdatedResponse(formulae: [], casks: [])
        }
        let task = Task<Sendable, Error> {
            try await client.outdatedPackages()
        }
        inFlight["outdated"] = task
        do {
            let result = try await task.value as! BrewOutdatedResponse
            outdatedPackages = result
            inFlight.removeValue(forKey: "outdated")
            return result
        } catch {
            inFlight.removeValue(forKey: "outdated")
            throw error
        }
    }

    /// Fetch services — returns cached if available, waits for in-flight fetch
    func getServices(forceRefresh: Bool = false) async throws -> [BrewServiceInfo] {
        if !forceRefresh, let cached = services { return cached }
        if let existing = inFlight["services"] {
            return try await existing.value as? [BrewServiceInfo] ?? []
        }
        let task = Task<Sendable, Error> {
            try await client.servicesList() as [BrewServiceInfo]
        }
        inFlight["services"] = task
        do {
            let result = try await task.value as! [BrewServiceInfo]
            services = result
            inFlight.removeValue(forKey: "services")
            return result
        } catch {
            inFlight.removeValue(forKey: "services")
            throw error
        }
    }

    /// Fetch taps — returns cached if available, waits for in-flight fetch
    func getTaps(forceRefresh: Bool = false) async throws -> [Tap] {
        if !forceRefresh, let cached = taps { return cached }
        if let existing = inFlight["taps"] {
            return try await existing.value as? [Tap] ?? []
        }
        let task = Task<Sendable, Error> {
            try await client.installedTaps() as [Tap]
        }
        inFlight["taps"] = task
        do {
            let result = try await task.value as! [Tap]
            taps = result
            inFlight.removeValue(forKey: "taps")
            return result
        } catch {
            inFlight.removeValue(forKey: "taps")
            throw error
        }
    }

    /// Fast tap names — `brew tap` returns in ~50ms
    func getTapNames(forceRefresh: Bool = false) async throws -> [String] {
        if !forceRefresh, let cached = tapNames { return cached }
        let result = try await client.installedTapNames()
        tapNames = result
        return result
    }

    /// Get brew version — returns cached if available
    func getBrewVersion(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let cached = brewVersion { return cached }
        let result = try await client.brewVersion()
        brewVersion = result
        return result
    }

    /// Get disk usage — computed off main thread, cached
    func getDiskUsage(forceRefresh: Bool = false) async -> String {
        if !forceRefresh, let cached = diskUsage { return cached }
        if let existing = inFlight["disk"] {
            return (try? await existing.value as? String) ?? "Calculating..."
        }
        let task = Task<Sendable, Error> {
            await DiskUsageCalculator.calculateBrewDiskUsage() as Sendable
        }
        inFlight["disk"] = task
        let result = (try? await task.value as? String) ?? "Calculating..."
        diskUsage = result
        inFlight.removeValue(forKey: "disk")
        return result
    }

    /// Get cache size — computed off main thread, cached
    func getCacheSize(forceRefresh: Bool = false) async -> String {
        if !forceRefresh, let cached = cacheUsage { return cached }
        if let existing = inFlight["cache"] {
            return (try? await existing.value as? String) ?? "Calculating..."
        }
        let task = Task<Sendable, Error> {
            await DiskUsageCalculator.cacheSize() as Sendable
        }
        inFlight["cache"] = task
        let result = (try? await task.value as? String) ?? "Calculating..."
        cacheUsage = result
        inFlight.removeValue(forKey: "cache")
        return result
    }

    /// Invalidate all caches — call after mutations (install/uninstall/upgrade)
    func invalidateAll() {
        installedPackages = nil
        outdatedPackages = nil
        services = nil
        taps = nil
        tapNames = nil
        diskUsage = nil
        cacheUsage = nil
    }

    /// Invalidate only package-related caches
    func invalidatePackages() {
        installedPackages = nil
        outdatedPackages = nil
        diskUsage = nil
    }

    /// Invalidate only services cache
    func invalidateServices() {
        services = nil
    }

    /// Invalidate only taps cache
    func invalidateTaps() {
        taps = nil
        tapNames = nil
    }
}

@Observable
@MainActor
final class AppState {
    var selectedSidebar: SidebarItem? = .dashboard
    var globalSearchText = ""
    var isOperationRunning = false
    var operationOutput: [String] = []
    var showOperationSheet = false
    var showOperationHistory = false
    var operationTitle = ""
    var operationHistory: [OperationRecord] = []
    var outdatedCount = 0
    var error: BrewError?
    var showError = false

    private var operationTask: Task<Void, Never>?

    let brewClient: any BrewClient
    let cache: BrewCache

    init(brewClient: any BrewClient) {
        self.brewClient = brewClient
        self.cache = BrewCache(client: brewClient)
    }

    func runOperation(title: String, stream: AsyncThrowingStream<String, Error>) async {
        operationTitle = title
        operationOutput = []
        isOperationRunning = true
        showOperationSheet = true

        var success = true
        let task = Task {
            do {
                for try await line in stream {
                    guard !Task.isCancelled else { break }
                    operationOutput.append(line)
                }
            } catch is CancellationError {
                operationOutput.append("Operation cancelled.")
                success = false
            } catch let error as BrewError {
                self.error = error
                operationOutput.append("Error: \(error.localizedDescription)")
                success = false
            } catch {
                if !Task.isCancelled {
                    operationOutput.append("Error: \(error.localizedDescription)")
                    success = false
                } else {
                    operationOutput.append("Operation cancelled.")
                    success = false
                }
            }
        }
        operationTask = task
        await task.value

        isOperationRunning = false
        operationTask = nil

        let record = OperationRecord(
            title: title,
            timestamp: Date(),
            output: operationOutput,
            success: success
        )
        operationHistory.insert(record, at: 0)
        if operationHistory.count > 100 {
            operationHistory = Array(operationHistory.prefix(100))
        }
    }

    func cancelOperation() {
        operationTask?.cancel()
    }

    func refreshOutdatedCount() async {
        do {
            let outdated = try await cache.getOutdatedPackages(forceRefresh: true)
            outdatedCount = outdated.formulae.count + outdated.casks.count
        } catch {}
    }
}
