import Foundation

final class LiveBrewClient: BrewClient, @unchecked Sendable {
    private let process: BrewProcess

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()

    init() throws {
        self.process = try BrewProcess()
    }

    init(brewPath: String) {
        self.process = BrewProcess(path: brewPath)
    }

    // MARK: - Package Info

    func installedPackages() async throws -> BrewInfoResponse {
        let result = try await process.run(["info", "--json=v2", "--installed"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "info --installed", exitCode: result.exitCode, stderr: result.stderr)
        }
        return try decodeJSON(result.stdout)
    }

    func packageInfo(_ name: String) async throws -> BrewInfoResponse {
        let result = try await process.run(["info", "--json=v2", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "info \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
        return try decodeJSON(result.stdout)
    }

    func outdatedPackages() async throws -> BrewOutdatedResponse {
        let result = try await process.run(["outdated", "--json=v2"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "outdated", exitCode: result.exitCode, stderr: result.stderr)
        }
        return try decodeJSON(result.stdout)
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let result = try await process.run(["search", query])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "search \(query)", exitCode: result.exitCode, stderr: result.stderr)
        }
        return TextOutputParser.parseSearchResults(result.stdout)
    }

    func searchPackagesInfo(_ names: [String]) async throws -> BrewInfoResponse {
        guard !names.isEmpty else {
            return BrewInfoResponse(formulae: [], casks: [])
        }
        // Try batch first
        let args = ["info", "--json=v2"] + names
        let result = try await process.run(args)
        if result.exitCode == 0 {
            return try decodeJSON(result.stdout)
        }
        // Batch failed — some names may be invalid. Fall back to individual lookups.
        var allFormulae: [Formula] = []
        var allCasks: [Cask] = []
        for name in names {
            let r = try await process.run(["info", "--json=v2", name])
            guard r.exitCode == 0 else { continue }
            if let info: BrewInfoResponse = try? decodeJSON(r.stdout) {
                allFormulae.append(contentsOf: info.formulae)
                allCasks.append(contentsOf: info.casks)
            }
        }
        return BrewInfoResponse(formulae: allFormulae, casks: allCasks)
    }

    // MARK: - Operations

    func install(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error> {
        var args = ["install"]
        if isCask { args.append("--cask") }
        args.append(name)
        return process.stream(args)
    }

    func uninstall(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error> {
        var args = ["uninstall"]
        if isCask { args.append("--cask") }
        args.append(name)
        return process.stream(args)
    }

    func upgrade(_ name: String?) -> AsyncThrowingStream<String, Error> {
        var args = ["upgrade"]
        if let name { args.append(name) }
        return process.stream(args, noAutoUpdate: false)
    }

    func update() -> AsyncThrowingStream<String, Error> {
        process.stream(["update"], noAutoUpdate: false)
    }

    // MARK: - Pin

    func pin(_ name: String) async throws {
        let result = try await process.run(["pin", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "pin \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    func unpin(_ name: String) async throws {
        let result = try await process.run(["unpin", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "unpin \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    // MARK: - Taps

    func installedTaps() async throws -> [Tap] {
        let result = try await process.run(["tap-info", "--json", "--installed"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "tap-info", exitCode: result.exitCode, stderr: result.stderr)
        }
        return try decodeJSON(result.stdout)
    }

    func addTap(_ name: String) -> AsyncThrowingStream<String, Error> {
        process.stream(["tap", name])
    }

    func removeTap(_ name: String) async throws {
        let result = try await process.run(["untap", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "untap \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    // MARK: - Services

    func servicesList() async throws -> [BrewServiceInfo] {
        let result = try await process.run(["services", "list", "--json"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "services list", exitCode: result.exitCode, stderr: result.stderr)
        }
        let text = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty || text == "[]" { return [] }
        return try decodeJSON(text)
    }

    func serviceStart(_ name: String) async throws {
        let result = try await process.run(["services", "start", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "services start \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    func serviceStop(_ name: String) async throws {
        let result = try await process.run(["services", "stop", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "services stop \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    func serviceRestart(_ name: String) async throws {
        let result = try await process.run(["services", "restart", name])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "services restart \(name)", exitCode: result.exitCode, stderr: result.stderr)
        }
    }

    // MARK: - Maintenance

    func doctor() -> AsyncThrowingStream<String, Error> {
        process.stream(["doctor"])
    }

    func cleanup(dryRun: Bool) -> AsyncThrowingStream<String, Error> {
        var args = ["cleanup"]
        if dryRun { args.append("--dry-run") }
        return process.stream(args)
    }

    // MARK: - Brewfile

    func brewfileDump() async throws -> String {
        let result = try await process.run(["bundle", "dump", "--describe", "--file=-"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "bundle dump", exitCode: result.exitCode, stderr: result.stderr)
        }
        return result.stdout
    }

    func brewfileInstall(from path: String) -> AsyncThrowingStream<String, Error> {
        process.stream(["bundle", "install", "--file=\(path)"])
    }

    // MARK: - Dependencies

    func reverseDependencies(_ name: String) async throws -> [String] {
        let result = try await process.run(["uses", "--installed", name])
        guard result.exitCode == 0 else { return [] }
        return result.stdout
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Disk Usage

    func packageDiskUsage(_ name: String, isCask: Bool) async throws -> String {
        let basePath: String
        if isCask {
            let result = try await process.run(["--caskroom"])
            basePath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            let result = try await process.run(["--cellar"])
            basePath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let path = "\(basePath)/\(name)"
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/du")
        proc.arguments = ["-sh", path]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = Pipe()
        try proc.run()
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        // du output: "58M\t/path/to/package"
        return output.components(separatedBy: "\t").first?.trimmingCharacters(in: .whitespaces) ?? "Unknown"
    }

    // MARK: - Meta

    func brewVersion() async throws -> String {
        let result = try await process.run(["--version"])
        guard result.exitCode == 0 else {
            throw BrewError.commandFailed(command: "--version", exitCode: result.exitCode, stderr: result.stderr)
        }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Private

    private func decodeJSON<T: Decodable>(_ string: String) throws -> T {
        guard let data = string.data(using: .utf8) else {
            throw BrewError.decodingFailed("Invalid UTF-8")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw BrewError.decodingFailed(error.localizedDescription)
        }
    }
}
