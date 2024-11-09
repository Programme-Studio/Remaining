import SwiftUI
import CoreData

extension DateEntity {
    func daysLeft() -> Int {
        let calendar = Calendar.current
        let timeZone = calendar.timeZone
        let currentDate = calendar.startOfDay(for: Date())

        guard let endDate = self.eventEnd else { return 0 }
        let endOfDay = calendar.startOfDay(for: endDate)

        let components = calendar.dateComponents(in: timeZone, from: currentDate)
        let currentStartOfDay = calendar.date(from: components) ?? Date()
        let daysLeft = calendar.dateComponents([.day], from: currentStartOfDay, to: endOfDay).day ?? 0

        return max(daysLeft, 0)
    }

    func daysCompleted() -> Int {
        let calendar = Calendar.current
        let timeZone = calendar.timeZone
        let currentDate = calendar.startOfDay(for: Date())

        guard let startDate = self.eventStart else { return 0 }
        let startOfDay = calendar.startOfDay(for: startDate)

        let components = calendar.dateComponents(in: timeZone, from: currentDate)
        let currentStartOfDay = calendar.date(from: components) ?? Date()
        let daysCompleted = calendar.dateComponents([.day], from: startOfDay, to: currentStartOfDay).day ?? 0

        return max(daysCompleted, 0)
    }

    func completionPercentage() -> Double {
        let totalDays = self.daysCompleted() + self.daysLeft()
        guard totalDays > 0 else { return 0 }
        return (Double(self.daysCompleted()) / Double(totalDays)) * 100
    }

    func percentageLeft() -> Double {
        return 100 - self.completionPercentage()
    }
}
