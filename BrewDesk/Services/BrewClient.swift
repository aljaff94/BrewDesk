import Foundation

protocol BrewClient: Sendable {
    // Package info
    func installedPackages() async throws -> BrewInfoResponse
    func packageInfo(_ name: String) async throws -> BrewInfoResponse
    func outdatedPackages() async throws -> BrewOutdatedResponse
    func search(_ query: String) async throws -> [SearchResult]
    func searchPackagesInfo(_ names: [String]) async throws -> BrewInfoResponse

    // Operations (streaming)
    func install(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error>
    func uninstall(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error>
    func upgrade(_ name: String?) -> AsyncThrowingStream<String, Error>
    func update() -> AsyncThrowingStream<String, Error>

    // Pin
    func pin(_ name: String) async throws
    func unpin(_ name: String) async throws

    // Taps
    func installedTaps() async throws -> [Tap]
    func addTap(_ name: String) -> AsyncThrowingStream<String, Error>
    func removeTap(_ name: String) async throws

    // Services
    func servicesList() async throws -> [BrewServiceInfo]
    func serviceStart(_ name: String) async throws
    func serviceStop(_ name: String) async throws
    func serviceRestart(_ name: String) async throws

    // Maintenance
    func doctor() -> AsyncThrowingStream<String, Error>
    func cleanup(dryRun: Bool) -> AsyncThrowingStream<String, Error>

    // Brewfile
    func brewfileDump() async throws -> String
    func brewfileInstall(from path: String) -> AsyncThrowingStream<String, Error>

    // Dependencies
    func reverseDependencies(_ name: String) async throws -> [String]

    // Disk usage
    func packageDiskUsage(_ name: String, isCask: Bool) async throws -> String

    // Meta
    func brewVersion() async throws -> String
}

struct SearchResult: Identifiable, Sendable {
    var id: String { "\(type.rawValue):\(name)" }
    let name: String
    let type: PackageType
}
