import Foundation

struct Cask: Codable, Identifiable, Sendable {
    var id: String { token }

    let token: String
    let fullToken: String
    let oldTokens: [String]
    let tap: String?
    let name: [String]
    let desc: String?
    let homepage: String?
    let url: String?
    let urlSpecs: URLSpecs?
    let version: String?
    let installed: String?
    let installedTime: Int?
    let bundleVersion: String?
    let bundleShortVersion: String?
    let outdated: Bool
    let sha256: String?
    let artifacts: [JSONValue]
    let caveats: String?
    let dependsOn: CaskDependsOn?
    let conflictsWith: CaskConflicts?
    let autoUpdates: Bool?
    let deprecated: Bool
    let deprecationDate: String?
    let deprecationReason: String?
    let disabled: Bool
    let disableDate: String?
    let disableReason: String?
    let languages: [String]?
    let rubySourcePath: String?
    let tapGitHead: String?

    var isInstalled: Bool { installed != nil }

    var displayName: String {
        name.first ?? token
    }

    var installedVersion: String? { installed }

    var latestVersion: String? { version }

    var artifactTypes: [String] {
        var types: [String] = []
        for artifact in artifacts {
            if case .dictionary(let dict) = artifact {
                types.append(contentsOf: dict.keys)
            }
        }
        return types
    }
}

struct URLSpecs: Codable, Sendable {
    let verified: String?
}

struct CaskDependsOn: Codable, Sendable {
    let macos: MacOSDependency?
    let cask: [String]?
    let formula: [String]?
}

struct MacOSDependency: Codable, Sendable {
    let conditions: [String: [String]]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        conditions = (try? container.decode([String: [String]].self)) ?? [:]
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(conditions)
    }
}

struct CaskConflicts: Codable, Sendable {
    let cask: [String]?
    let formula: [String]?
}

// Flexible JSON value for heterogeneous cask artifacts
enum JSONValue: Codable, Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case dictionary([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([JSONValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: JSONValue].self) {
            self = .dictionary(dict)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode JSONValue"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let a): try container.encode(a)
        case .dictionary(let d): try container.encode(d)
        case .null: try container.encodeNil()
        }
    }
}
