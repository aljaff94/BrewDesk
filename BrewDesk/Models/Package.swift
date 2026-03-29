import Foundation

enum Package: Identifiable, Sendable {
    case formula(Formula)
    case cask(Cask)

    var id: String {
        switch self {
        case .formula(let f): return "formula:\(f.fullName)"
        case .cask(let c): return "cask:\(c.token)"
        }
    }

    var name: String {
        switch self {
        case .formula(let f): return f.name
        case .cask(let c): return c.token
        }
    }

    var displayName: String {
        switch self {
        case .formula(let f): return f.displayName
        case .cask(let c): return c.displayName
        }
    }

    var description: String? {
        switch self {
        case .formula(let f): return f.desc
        case .cask(let c): return c.desc
        }
    }

    var isInstalled: Bool {
        switch self {
        case .formula(let f): return f.isInstalled
        case .cask(let c): return c.isInstalled
        }
    }

    var installedVersion: String? {
        switch self {
        case .formula(let f): return f.installedVersion
        case .cask(let c): return c.installedVersion
        }
    }

    var latestVersion: String? {
        switch self {
        case .formula(let f): return f.stableVersion
        case .cask(let c): return c.latestVersion
        }
    }

    var isOutdated: Bool {
        switch self {
        case .formula(let f): return f.outdated
        case .cask(let c): return c.outdated
        }
    }

    var homepage: String? {
        switch self {
        case .formula(let f): return f.homepage
        case .cask(let c): return c.homepage
        }
    }

    var tap: String? {
        switch self {
        case .formula(let f): return f.tap
        case .cask(let c): return c.tap
        }
    }

    var packageType: PackageType {
        switch self {
        case .formula: return .formula
        case .cask: return .cask
        }
    }

    var caveats: String? {
        switch self {
        case .formula(let f): return f.caveats
        case .cask(let c): return c.caveats
        }
    }

    var isDeprecated: Bool {
        switch self {
        case .formula(let f): return f.deprecated
        case .cask(let c): return c.deprecated
        }
    }

    var installDate: Date? {
        switch self {
        case .formula(let f):
            guard let time = f.installed.first?.time else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(time))
        case .cask(let c):
            guard let time = c.installedTime else { return nil }
            return Date(timeIntervalSince1970: TimeInterval(time))
        }
    }
}

enum PackageType: String, CaseIterable, Sendable {
    case formula = "Formula"
    case cask = "Cask"
}

enum PackageFilter: String, CaseIterable, Sendable {
    case all = "All"
    case installed = "Installed"
    case notInstalled = "Not Installed"
    case outdated = "Outdated"
}
