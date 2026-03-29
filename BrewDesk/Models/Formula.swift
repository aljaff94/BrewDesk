import Foundation

struct Formula: Codable, Identifiable, Hashable, Sendable {
    var id: String { fullName }

    static func == (lhs: Formula, rhs: Formula) -> Bool {
        lhs.fullName == rhs.fullName
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(fullName)
    }

    let name: String
    let fullName: String
    let tap: String?
    let oldnames: [String]
    let aliases: [String]
    let versionedFormulae: [String]
    let desc: String?
    let license: String?
    let homepage: String?
    let versions: FormulaVersions
    let revision: Int
    let versionScheme: Int
    let bottle: [String: BottleSpec]
    let kegOnly: Bool
    let kegOnlyReason: KegOnlyReason?
    let options: [String]
    let buildDependencies: [String]
    let dependencies: [String]
    let testDependencies: [String]
    let recommendedDependencies: [String]
    let optionalDependencies: [String]
    let usesFromMacos: [UsesFromMacos]
    let caveats: String?
    let installed: [InstalledVersion]
    let linkedKeg: String?
    let pinned: Bool
    let outdated: Bool
    let deprecated: Bool
    let deprecationDate: String?
    let deprecationReason: String?
    let disabled: Bool
    let disableDate: String?
    let disableReason: String?
    let postInstallDefined: Bool
    let service: FormulaService?
    let conflictsWith: [String]
    let conflictsWithReasons: [String]
    let rubySourcePath: String?

    var isInstalled: Bool { !installed.isEmpty }

    var installedVersion: String? {
        installed.first?.version
    }

    var stableVersion: String? {
        versions.stable
    }

    var displayName: String { name }

    var allDependencies: [String] {
        dependencies + buildDependencies
    }
}

struct FormulaVersions: Codable, Sendable {
    let stable: String?
    let head: String?
    let bottle: Bool
}

struct InstalledVersion: Codable, Sendable {
    let version: String
    let usedOptions: [String]
    let builtAsBottle: Bool
    let pouredFromBottle: Bool
    let time: Int?
    let runtimeDependencies: [RuntimeDependency]?
    let installedAsDependency: Bool
    let installedOnRequest: Bool
}

struct RuntimeDependency: Codable, Sendable {
    let fullName: String
    let version: String
    let revision: Int
    let pkgVersion: String
    let declaredDirectly: Bool
}

struct BottleSpec: Codable, Sendable {
    let rebuild: Int
    let rootUrl: String
    let files: [String: BottleFile]
}

struct BottleFile: Codable, Sendable {
    let cellar: String
    let url: String
    let sha256: String
}

struct KegOnlyReason: Codable, Sendable {
    let reason: String
    let explanation: String
}

struct FormulaService: Codable, Sendable {
    let name: String?
    let run: ServiceRun?
    let runType: String?
    let keepAlive: ServiceKeepAlive?
    let workingDir: String?
    let logPath: String?
    let errorLogPath: String?

}

enum ServiceRun: Codable, Sendable {
    case string(String)
    case array([String])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .string(s)
        } else {
            self = .array(try container.decode([String].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .array(let a): try container.encode(a)
        }
    }
}

enum ServiceKeepAlive: Codable, Sendable {
    case bool(Bool)
    case dict([String: Bool])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else {
            self = .dict(try container.decode([String: Bool].self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .bool(let b): try container.encode(b)
        case .dict(let d): try container.encode(d)
        }
    }
}

enum UsesFromMacos: Codable, Sendable {
    case simple(String)
    case conditional(name: String, reason: String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let s = try? container.decode(String.self) {
            self = .simple(s)
        } else {
            let dict = try container.decode([String: String].self)
            guard let (name, reason) = dict.first else {
                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Empty uses_from_macos dict"
                )
            }
            self = .conditional(name: name, reason: reason)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .simple(let s):
            try container.encode(s)
        case .conditional(let name, let reason):
            try container.encode([name: reason])
        }
    }

    var name: String {
        switch self {
        case .simple(let s): return s
        case .conditional(let name, _): return name
        }
    }
}
