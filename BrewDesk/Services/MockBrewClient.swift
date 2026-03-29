import Foundation

final class MockBrewClient: BrewClient, @unchecked Sendable {
    static let sampleFormulae: [Formula] = [
        Formula(
            name: "wget", fullName: "wget", tap: "homebrew/core",
            oldnames: [], aliases: [], versionedFormulae: [],
            desc: "Internet file retriever", license: "GPL-3.0-or-later",
            homepage: "https://www.gnu.org/software/wget/",
            versions: FormulaVersions(stable: "1.24.5", head: "HEAD", bottle: true),
            revision: 0, versionScheme: 0, bottle: [:],
            kegOnly: false, kegOnlyReason: nil, options: [],
            buildDependencies: [], dependencies: ["libidn2", "openssl@3"],
            testDependencies: [], recommendedDependencies: [],
            optionalDependencies: [], usesFromMacos: [],
            caveats: nil,
            installed: [InstalledVersion(
                version: "1.24.5", usedOptions: [],
                builtAsBottle: true, pouredFromBottle: true,
                time: 1700000000, runtimeDependencies: nil,
                installedAsDependency: false, installedOnRequest: true
            )],
            linkedKeg: "1.24.5", pinned: false, outdated: false,
            deprecated: false, deprecationDate: nil, deprecationReason: nil,
            disabled: false, disableDate: nil, disableReason: nil,
            postInstallDefined: false, service: nil,
            conflictsWith: [], conflictsWithReasons: [],
            rubySourcePath: nil
        ),
        Formula(
            name: "git", fullName: "git", tap: "homebrew/core",
            oldnames: [], aliases: [], versionedFormulae: [],
            desc: "Distributed revision control system", license: "GPL-2.0-only",
            homepage: "https://git-scm.com",
            versions: FormulaVersions(stable: "2.44.0", head: "HEAD", bottle: true),
            revision: 0, versionScheme: 0, bottle: [:],
            kegOnly: false, kegOnlyReason: nil, options: [],
            buildDependencies: [], dependencies: ["pcre2", "gettext"],
            testDependencies: [], recommendedDependencies: [],
            optionalDependencies: [], usesFromMacos: [],
            caveats: nil,
            installed: [InstalledVersion(
                version: "2.43.0", usedOptions: [],
                builtAsBottle: true, pouredFromBottle: true,
                time: 1699000000, runtimeDependencies: nil,
                installedAsDependency: false, installedOnRequest: true
            )],
            linkedKeg: "2.43.0", pinned: false, outdated: true,
            deprecated: false, deprecationDate: nil, deprecationReason: nil,
            disabled: false, disableDate: nil, disableReason: nil,
            postInstallDefined: false, service: nil,
            conflictsWith: [], conflictsWithReasons: [],
            rubySourcePath: nil
        )
    ]

    static let sampleCasks: [Cask] = [
        Cask(
            token: "firefox", fullToken: "firefox", oldTokens: [],
            tap: "homebrew/cask", name: ["Mozilla Firefox"],
            desc: "Web browser", homepage: "https://www.mozilla.org/firefox/",
            url: "https://download.mozilla.org/", urlSpecs: nil,
            version: "124.0", installed: "123.0",
            installedTime: 1700000000, bundleVersion: nil,
            bundleShortVersion: nil, outdated: true, sha256: nil,
            artifacts: [], caveats: nil, dependsOn: nil,
            conflictsWith: nil, autoUpdates: true,
            deprecated: false, deprecationDate: nil, deprecationReason: nil,
            disabled: false, disableDate: nil, disableReason: nil,
            languages: nil, rubySourcePath: nil, tapGitHead: nil
        )
    ]

    func installedPackages() async throws -> BrewInfoResponse {
        BrewInfoResponse(formulae: Self.sampleFormulae, casks: Self.sampleCasks)
    }

    func packageInfo(_ name: String) async throws -> BrewInfoResponse {
        let formulae = Self.sampleFormulae.filter { $0.name == name }
        let casks = Self.sampleCasks.filter { $0.token == name }
        return BrewInfoResponse(formulae: formulae, casks: casks)
    }

    func outdatedPackages() async throws -> BrewOutdatedResponse {
        BrewOutdatedResponse(
            formulae: [OutdatedFormula(name: "git", installedVersions: ["2.43.0"], currentVersion: "2.44.0", pinned: false, pinnedVersion: nil)],
            casks: [OutdatedCask(name: "firefox", installedVersions: ["123.0"], currentVersion: "124.0")]
        )
    }

    func search(_ query: String) async throws -> [SearchResult] {
        let allNames = Self.sampleFormulae.map { SearchResult(name: $0.name, type: .formula) }
            + Self.sampleCasks.map { SearchResult(name: $0.token, type: .cask) }
        return allNames.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    func searchPackagesInfo(_ names: [String]) async throws -> BrewInfoResponse {
        let formulae = Self.sampleFormulae.filter { names.contains($0.name) }
        let casks = Self.sampleCasks.filter { names.contains($0.token) }
        return BrewInfoResponse(formulae: formulae, casks: casks)
    }

    func install(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error> {
        mockStream(lines: [
            "==> Downloading \(name)...",
            "==> Installing \(name)",
            "==> Pouring \(name)",
            "🍺  \(name) was successfully installed!"
        ])
    }

    func uninstall(_ name: String, isCask: Bool) -> AsyncThrowingStream<String, Error> {
        mockStream(lines: ["Uninstalling \(name)...", "Successfully uninstalled \(name)"])
    }

    func upgrade(_ name: String?) -> AsyncThrowingStream<String, Error> {
        let target = name ?? "all packages"
        return mockStream(lines: ["==> Upgrading \(target)...", "==> Upgraded successfully"])
    }

    func update() -> AsyncThrowingStream<String, Error> {
        mockStream(lines: ["Updated 1 tap (homebrew/core).", "Already up-to-date."])
    }

    func pin(_ name: String) async throws {}
    func unpin(_ name: String) async throws {}

    func installedTaps() async throws -> [Tap] {
        [Tap(
            name: "homebrew/core", user: "homebrew", repo: "core",
            path: "/opt/homebrew/Library/Taps/homebrew/homebrew-core",
            installed: true, official: true, formulaNames: ["wget", "git"],
            caskTokens: [], formulaFiles: [], caskFiles: [],
            commandFiles: [], remote: "https://github.com/Homebrew/homebrew-core",
            customRemote: false, isPrivate: false,
            head: "abc123", lastCommit: "2 hours ago", branch: "master"
        )]
    }

    func addTap(_ name: String) -> AsyncThrowingStream<String, Error> {
        mockStream(lines: ["==> Tapping \(name)...", "Tapped \(name) successfully"])
    }

    func removeTap(_ name: String) async throws {}

    func servicesList() async throws -> [BrewServiceInfo] {
        [
            BrewServiceInfo(name: "postgresql@16", status: "started", user: "ahmed", file: nil, exitCode: 0, pid: 1234, loaded: true),
            BrewServiceInfo(name: "redis", status: "stopped", user: nil, file: nil, exitCode: nil, pid: nil, loaded: false)
        ]
    }

    func serviceStart(_ name: String) async throws {}
    func serviceStop(_ name: String) async throws {}
    func serviceRestart(_ name: String) async throws {}

    func doctor() -> AsyncThrowingStream<String, Error> {
        mockStream(lines: [
            "Your system is ready to brew."
        ])
    }

    func cleanup(dryRun: Bool) -> AsyncThrowingStream<String, Error> {
        mockStream(lines: [
            dryRun ? "Would remove: /opt/homebrew/Cellar/old-pkg (45.2MB)" : "Removing old packages...",
            dryRun ? "Would remove: ~/Library/Caches/Homebrew (123MB)" : "Cleaned up successfully"
        ])
    }

    func brewfileDump() async throws -> String {
        """
        tap "homebrew/core"
        brew "wget"
        brew "git"
        cask "firefox"
        """
    }

    func brewfileInstall(from path: String) -> AsyncThrowingStream<String, Error> {
        mockStream(lines: ["Installing from Brewfile...", "All dependencies installed."])
    }

    func reverseDependencies(_ name: String) async throws -> [String] {
        if name == "openssl@3" { return ["wget"] }
        return []
    }

    func packageDiskUsage(_ name: String, isCask: Bool) async throws -> String {
        "45.2M"
    }

    func brewVersion() async throws -> String {
        "Homebrew 4.2.0"
    }

    private func mockStream(lines: [String]) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                for line in lines {
                    try await Task.sleep(for: .milliseconds(300))
                    continuation.yield(line)
                }
                continuation.finish()
            }
        }
    }
}
