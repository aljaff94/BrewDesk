import Foundation

struct BrewfileEntry: Identifiable, Sendable {
    let id = UUID()
    let type: EntryType
    let name: String
    let comment: String?

    enum EntryType: String, CaseIterable, Sendable {
        case tap
        case brew
        case cask
    }
}

enum BrewfileParser {
    static func parse(_ content: String) -> [BrewfileEntry] {
        var entries: [BrewfileEntry] = []

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty || trimmed.starts(with: "#") { continue }

            for type in BrewfileEntry.EntryType.allCases {
                let prefix = "\(type.rawValue) \""
                if trimmed.starts(with: prefix) {
                    let rest = trimmed.dropFirst(prefix.count)
                    if let quoteEnd = rest.firstIndex(of: "\"") {
                        let name = String(rest[rest.startIndex..<quoteEnd])
                        let afterQuote = rest[rest.index(after: quoteEnd)...]
                        var comment: String?
                        if let hashIndex = afterQuote.firstIndex(of: "#") {
                            comment = String(afterQuote[afterQuote.index(after: hashIndex)...])
                                .trimmingCharacters(in: .whitespaces)
                        }
                        entries.append(BrewfileEntry(type: type, name: name, comment: comment))
                    }
                    break
                }
            }
        }

        return entries
    }

    static func generate(from entries: [BrewfileEntry]) -> String {
        var lines: [String] = []

        let grouped = Dictionary(grouping: entries, by: \.type)

        for type in BrewfileEntry.EntryType.allCases {
            guard let typeEntries = grouped[type], !typeEntries.isEmpty else { continue }
            for entry in typeEntries {
                var line = "\(type.rawValue) \"\(entry.name)\""
                if let comment = entry.comment {
                    line += " # \(comment)"
                }
                lines.append(line)
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }
}
