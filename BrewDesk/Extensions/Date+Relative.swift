import Foundation

extension Date {
    var relativeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}

extension Int {
    var dateFromTimestamp: Date {
        Date(timeIntervalSince1970: TimeInterval(self))
    }
}
