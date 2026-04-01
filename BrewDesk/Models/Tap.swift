import Foundation

struct Tap: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let user: String
    let repo: String
    let path: String
    let installed: Bool
    let official: Bool
    let formulaNames: [String]
    let caskTokens: [String]
    let formulaFiles: [String]?
    let caskFiles: [String]?
    let commandFiles: [String]?
    let remote: String?
    let customRemote: Bool?
    let isPrivate: Bool?
    let head: String?
    let lastCommit: String?
    let branch: String?

    enum CodingKeys: String, CodingKey {
        case name, user, repo, path, installed, official
        case formulaNames, caskTokens, formulaFiles, caskFiles, commandFiles
        case remote, customRemote
        case isPrivate = "private"
        case head = "HEAD"
        case lastCommit, branch
    }

    var formulaCount: Int { formulaNames.count }
    var caskCount: Int { caskTokens.count }
    var totalPackages: Int { formulaCount + caskCount }

    /// Create a lightweight tap from just a name (from `brew tap`)
    static func fromName(_ name: String) -> Tap {
        let parts = name.split(separator: "/")
        let user = parts.count >= 1 ? String(parts[0]) : ""
        let repo = parts.count >= 2 ? String(parts[1]) : ""
        let isOfficial = user == "homebrew"
        return Tap(
            name: name, user: user, repo: repo,
            path: "", installed: true, official: isOfficial,
            formulaNames: [], caskTokens: [],
            formulaFiles: nil, caskFiles: nil, commandFiles: nil,
            remote: nil, customRemote: nil, isPrivate: nil,
            head: nil, lastCommit: nil, branch: nil
        )
    }

    /// Whether this is a lightweight tap (from `brew tap` only, no details yet)
    var isLightweight: Bool { path.isEmpty }
}
