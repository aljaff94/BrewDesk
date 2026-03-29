import SwiftUI

enum SidebarItem: String, CaseIterable, Identifiable, Sendable {
    case dashboard
    case formulae
    case casks
    case outdated
    case services
    case taps
    case dependencies
    case maintenance
    case brewfile

    var id: String { rawValue }

    var label: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .formulae: return "Formulae"
        case .casks: return "Casks"
        case .outdated: return "Outdated"
        case .services: return "Services"
        case .taps: return "Taps"
        case .dependencies: return "Dependencies"
        case .maintenance: return "Maintenance"
        case .brewfile: return "Brewfile"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: return "gauge.with.dots.needle.33percent"
        case .formulae: return "terminal"
        case .casks: return "macwindow"
        case .outdated: return "arrow.triangle.2.circlepath"
        case .services: return "gearshape.2"
        case .taps: return "spigot"
        case .dependencies: return "point.3.connected.trianglepath.dotted"
        case .maintenance: return "wrench.and.screwdriver"
        case .brewfile: return "doc.text"
        }
    }

    var section: SidebarSection {
        switch self {
        case .dashboard: return .overview
        case .formulae, .casks, .outdated: return .packages
        case .services, .taps, .dependencies: return .management
        case .maintenance, .brewfile: return .tools
        }
    }
}

enum SidebarSection: String, CaseIterable, Sendable {
    case overview = "Overview"
    case packages = "Packages"
    case management = "Management"
    case tools = "Tools"

    var items: [SidebarItem] {
        SidebarItem.allCases.filter { $0.section == self }
    }
}
