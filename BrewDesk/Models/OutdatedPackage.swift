import Foundation

struct OutdatedFormula: Codable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let installedVersions: [String]
    let currentVersion: String
    let pinned: Bool
    let pinnedVersion: String?
}

struct OutdatedCask: Codable, Identifiable, Sendable {
    var id: String { name }
    let name: String
    let installedVersions: [String]
    let currentVersion: String
}
