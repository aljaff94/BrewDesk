import Foundation

struct BrewServiceInfo: Codable, Identifiable, Sendable {
    var id: String { name }

    let name: String
    let status: String?
    let user: String?
    let file: String?
    let exitCode: Int?
    let pid: Int?
    let loaded: Bool?

    enum CodingKeys: String, CodingKey {
        case name, status, user, file
        case exitCode = "exit_code"
        case pid, loaded
    }

    var isRunning: Bool {
        status == "started"
    }

    var statusDisplay: ServiceStatus {
        switch status {
        case "started": return .running
        case "stopped", "none": return .stopped
        case "error": return .error
        default: return .unknown
        }
    }
}

enum ServiceStatus: String, Sendable {
    case running = "Running"
    case stopped = "Stopped"
    case error = "Error"
    case unknown = "Unknown"
}
