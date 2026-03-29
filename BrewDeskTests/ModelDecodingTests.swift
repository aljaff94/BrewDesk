import Testing
@testable import BrewDesk

@Test func testSearchResultsParsing() {
    let output = """
    ==> Formulae
    wget
    wget2
    ==> Casks
    wget-gui
    """

    let results = TextOutputParser.parseSearchResults(output)
    #expect(results.count == 3)
    #expect(results[0].name == "wget")
    #expect(results[0].type == .formula)
    #expect(results[2].name == "wget-gui")
    #expect(results[2].type == .cask)
}

@Test func testDoctorOutputParsing() {
    let output = """
    Warning: Some outdated formulae
    These are old packages.

    Warning: Another issue
    This is a problem.
    """

    let warnings = TextOutputParser.parseDoctorOutput(output)
    #expect(warnings.count == 2)
    #expect(warnings[0].message.contains("outdated"))
}

@Test func testCleanupOutputParsing() {
    let output = """
    Would remove: /opt/homebrew/Cellar/old-pkg/1.0 (45.2MB)
    Would remove: /opt/homebrew/Cellar/another-pkg/2.0 (12.1MB)
    """

    let items = TextOutputParser.parseCleanupOutput(output)
    #expect(items.count == 2)
    #expect(items[0].size == "45.2MB")
}

@Test func testBrewfileParser() {
    let content = """
    tap "homebrew/core"
    brew "wget" # Internet file retriever
    brew "git"
    cask "firefox"
    """

    let entries = BrewfileParser.parse(content)
    #expect(entries.count == 4)
    #expect(entries[0].type == .tap)
    #expect(entries[1].type == .brew)
    #expect(entries[1].comment == "Internet file retriever")
    #expect(entries[3].type == .cask)
}

@Test func testBrewfileGeneration() {
    let entries = [
        BrewfileEntry(type: .tap, name: "homebrew/core", comment: nil),
        BrewfileEntry(type: .brew, name: "wget", comment: "downloader"),
        BrewfileEntry(type: .cask, name: "firefox", comment: nil),
    ]

    let output = BrewfileParser.generate(from: entries)
    #expect(output.contains("tap \"homebrew/core\""))
    #expect(output.contains("brew \"wget\" # downloader"))
    #expect(output.contains("cask \"firefox\""))
}
