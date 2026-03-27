import Foundation

extension Date {
    var shortDate: String {
        formatted(date: .abbreviated, time: .omitted)
    }

    var shortDateTime: String {
        formatted(date: .abbreviated, time: .shortened)
    }

    var timeOnly: String {
        formatted(date: .omitted, time: .shortened)
    }

    var relativeDay: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(self) { return "Today" }
        if calendar.isDateInYesterday(self) { return "Yesterday" }
        return shortDate
    }
}

extension Int {
    var durationString: String {
        let minutes = self / 60
        let seconds = self % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        }
        return "\(seconds)s"
    }
}
