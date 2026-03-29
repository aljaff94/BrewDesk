import Foundation

enum TextOutputParser {
    static func parseSearchResults(_ output: String) -> [SearchResult] {
        var results: [SearchResult] = []
        var currentType: PackageType = .formula

        for line in output.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.starts(with: "==> Formulae") {
                currentType = .formula
                continue
            }
            if trimmed.starts(with: "==> Casks") {
                currentType = .cask
                continue
            }
            if trimmed.starts(with: "==>") { continue }

            results.append(SearchResult(name: trimmed, type: currentType))
        }

        return results
    }

    struct DoctorWarning: Identifiable, Sendable {
        let id = UUID()
        let message: String
    }

    static func parseDoctorOutput(_ output: String) -> [DoctorWarning] {
        var warnings: [DoctorWarning] = []
        var currentWarning = ""

        for line in output.components(separatedBy: "\n") {
            if line.starts(with: "Warning:") {
                if !currentWarning.isEmpty {
                    warnings.append(DoctorWarning(message: currentWarning.trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                currentWarning = line
            } else if !currentWarning.isEmpty && !line.isEmpty {
                currentWarning += "\n" + line
            } else if !currentWarning.isEmpty && line.isEmpty {
                warnings.append(DoctorWarning(message: currentWarning.trimmingCharacters(in: .whitespacesAndNewlines)))
                currentWarning = ""
            }
        }

        if !currentWarning.isEmpty {
            warnings.append(DoctorWarning(message: currentWarning.trimmingCharacters(in: .whitespacesAndNewlines)))
        }

        return warnings
    }

    struct CleanupItem: Identifiable, Sendable {
        let id = UUID()
        let path: String
        let size: String
    }

    static func parseCleanupOutput(_ output: String) -> [CleanupItem] {
        var items: [CleanupItem] = []

        for line in output.components(separatedBy: "\n") {
            if line.starts(with: "Would remove:") || line.starts(with: "Removing:") {
                let content = line
                    .replacingOccurrences(of: "Would remove: ", with: "")
                    .replacingOccurrences(of: "Removing: ", with: "")

                if let parenRange = content.range(of: " (", options: .backwards) {
                    let path = String(content[content.startIndex..<parenRange.lowerBound])
                    let size = String(content[parenRange.upperBound...]).replacingOccurrences(of: ")", with: "")
                    items.append(CleanupItem(path: path, size: size))
                } else {
                    items.append(CleanupItem(path: content, size: ""))
                }
            }
        }

        return items
    }
}
