import Foundation

struct ProcessResult: Sendable {
    let stdout: String
    let stderr: String
    let exitCode: Int32
}

enum BrewError: LocalizedError, Sendable {
    case brewNotFound
    case commandFailed(command: String, exitCode: Int32, stderr: String)
    case decodingFailed(String)
    case timeout

    var errorDescription: String? {
        switch self {
        case .brewNotFound:
            return "Homebrew not found. Please install Homebrew first."
        case .commandFailed(let cmd, let code, let stderr):
            return "Command '\(cmd)' failed (exit \(code)): \(stderr)"
        case .decodingFailed(let detail):
            return "Failed to parse brew output: \(detail)"
        case .timeout:
            return "Command timed out."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .brewNotFound:
            return "Visit https://brew.sh to install Homebrew."
        case .commandFailed:
            return "Try running the command in Terminal to see detailed output."
        case .decodingFailed:
            return "This may be a Homebrew version incompatibility."
        case .timeout:
            return "Try again or check your network connection."
        }
    }
}

actor BrewProcess {
    let brewPath: String

    private var baseEnvironment: [String: String] {
        var env = ProcessInfo.processInfo.environment
        env["HOMEBREW_NO_COLOR"] = "1"
        env["HOMEBREW_NO_EMOJI"] = "1"
        return env
    }

    init() throws {
        guard let path = BrewPathResolver.resolve() else {
            throw BrewError.brewNotFound
        }
        self.brewPath = path
    }

    init(path: String) {
        self.brewPath = path
    }

    func run(_ arguments: [String], noAutoUpdate: Bool = true) async throws -> ProcessResult {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: brewPath)
        process.arguments = arguments

        var env = baseEnvironment
        if noAutoUpdate {
            env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
        }
        process.environment = env

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        try process.run()

        // Read output asynchronously
        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

        process.waitUntilExit()

        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

        return ProcessResult(stdout: stdout, stderr: stderr, exitCode: process.terminationStatus)
    }

    nonisolated func stream(_ arguments: [String], noAutoUpdate: Bool = false) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: brewPath)
            process.arguments = arguments

            var env = ProcessInfo.processInfo.environment
            env["HOMEBREW_NO_COLOR"] = "1"
            env["HOMEBREW_NO_EMOJI"] = "1"
            if noAutoUpdate {
                env["HOMEBREW_NO_AUTO_UPDATE"] = "1"
            }
            process.environment = env

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            let lineBuffer = LineBuffer()

            stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty { return }
                guard let text = String(data: data, encoding: .utf8) else { return }
                let lines = lineBuffer.append(text)
                for line in lines {
                    continuation.yield(line)
                }
            }

            stderrPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                if data.isEmpty { return }
                guard let text = String(data: data, encoding: .utf8) else { return }
                for line in text.components(separatedBy: "\n") where !line.isEmpty {
                    continuation.yield(line)
                }
            }

            process.terminationHandler = { proc in
                stdoutPipe.fileHandleForReading.readabilityHandler = nil
                stderrPipe.fileHandleForReading.readabilityHandler = nil

                // Flush remaining buffer
                if let remaining = lineBuffer.flush() {
                    continuation.yield(remaining)
                }

                if proc.terminationStatus != 0 {
                    continuation.finish(throwing: BrewError.commandFailed(
                        command: arguments.joined(separator: " "),
                        exitCode: proc.terminationStatus,
                        stderr: ""
                    ))
                } else {
                    continuation.finish()
                }
            }

            do {
                try process.run()
            } catch {
                continuation.finish(throwing: error)
            }

            continuation.onTermination = { @Sendable _ in
                if process.isRunning {
                    process.terminate()
                }
            }
        }
    }
}

// Thread-safe line buffer for streaming process output
private final class LineBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""

    func append(_ text: String) -> [String] {
        lock.lock()
        defer { lock.unlock() }

        buffer += text
        var lines: [String] = []
        while let newlineRange = buffer.range(of: "\n") {
            let line = String(buffer[buffer.startIndex..<newlineRange.lowerBound])
            buffer = String(buffer[newlineRange.upperBound...])
            lines.append(line)
        }
        return lines
    }

    func flush() -> String? {
        lock.lock()
        defer { lock.unlock() }

        let remaining = buffer
        buffer = ""
        return remaining.isEmpty ? nil : remaining
    }
}
