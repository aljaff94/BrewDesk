import Foundation

enum DiskUsageCalculator {
    static func calculateBrewDiskUsage() async -> String {
        await Task.detached(priority: .utility) {
            let paths = [
                "/opt/homebrew/Cellar",
                "/opt/homebrew/Caskroom",
                "/usr/local/Cellar",
                "/usr/local/Caskroom"
            ]

            var totalBytes: UInt64 = 0
            let fm = FileManager.default

            for path in paths {
                guard fm.fileExists(atPath: path) else { continue }
                totalBytes += directorySize(atPath: path)
            }

            return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
        }.value
    }

    static func cacheSize() async -> String {
        await Task.detached(priority: .utility) {
            let cachePaths = [
                NSHomeDirectory() + "/Library/Caches/Homebrew",
                "/opt/homebrew/var/homebrew/tmp"
            ]

            var totalBytes: UInt64 = 0
            let fm = FileManager.default

            for path in cachePaths {
                guard fm.fileExists(atPath: path) else { continue }
                totalBytes += directorySize(atPath: path)
            }

            return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
        }.value
    }

    private static func directorySize(atPath path: String) -> UInt64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(atPath: path) else { return 0 }

        var size: UInt64 = 0
        while let file = enumerator.nextObject() as? String {
            let fullPath = (path as NSString).appendingPathComponent(file)
            if let attrs = try? fm.attributesOfItem(atPath: fullPath),
               let fileSize = attrs[.size] as? UInt64 {
                size += fileSize
            }
        }
        return size
    }
}
