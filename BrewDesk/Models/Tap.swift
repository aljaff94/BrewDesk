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
}
