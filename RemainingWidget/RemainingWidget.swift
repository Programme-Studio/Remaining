import WidgetKit
import SwiftUI
import CoreData

struct Provider: AppIntentTimelineProvider {
    typealias Intent = ConfigurationAppIntent
    
    let container: NSPersistentContainer

    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), primaryData: DateEntityData(), secondaryData: nil, viewStyle: .singleProgressBar)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let data = fetchDateData()
        return SimpleEntry(date: Date(), primaryData: data.primaryData, secondaryData: data.secondaryData, viewStyle: configuration.viewStyle)
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let currentDate = Date()

        // Generate entries for the next 5 hours
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let data = fetchDateData()
            let entry = SimpleEntry(date: entryDate, primaryData: data.primaryData, secondaryData: data.secondaryData, viewStyle: configuration.viewStyle)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

    func fetchDateData() -> (primaryData: DateEntityData, secondaryData: DateEntityData?) {
        let request: NSFetchRequest<DateEntity> = DateEntity.fetchRequest()
        request.predicate = NSPredicate(format: "isWidgetSelected == %@", NSNumber(value: true))

        let secondaryRequest: NSFetchRequest<DateEntity> = DateEntity.fetchRequest()
        secondaryRequest.predicate = NSPredicate(format: "secondWidgetSelected == %@", NSNumber(value: true))

        do {
            let result = try container.viewContext.fetch(request)
            let secondaryResult = try container.viewContext.fetch(secondaryRequest)
            
            var primaryData = DateEntityData()
            var secondaryData: DateEntityData? = nil
            
            if let dateEntity = result.first {
                primaryData = dateEntity.toDateEntityData()
            } else {
                print("No countdown selected for widget")
            }
            
            if let secondaryDateEntity = secondaryResult.first {
                secondaryData = secondaryDateEntity.toDateEntityData()
            } else {
                print("No secondary countdown selected for widget")
            }
            
            return (primaryData: primaryData, secondaryData: secondaryData)
        } catch {
            print("Failed to fetch date data: \(error)")
            return (primaryData: DateEntityData(), secondaryData: nil)
        }
    }
}

struct DateEntityData {
    var startDate: Date = Date()
    var endDate: Date = Date()
    var remainingDays: Int = 0
    var completedDays: Int = 0
    var totalDays: Int = 0
    var percentageCompleted: Double = 0.0
    var gradientName: String = "PinkPurple"
    var title: String = ""
}

extension DateEntity {
    func toDateEntityData() -> DateEntityData {
        let remainingDays = self.daysLeft()
        let completedDays = self.daysCompleted()
        let totalDays = completedDays + remainingDays
        let percentageCompleted = self.completionPercentage()
        
        return DateEntityData(
            startDate: self.eventStart ?? Date(),
            endDate: self.eventEnd ?? Date(),
            remainingDays: remainingDays,
            completedDays: completedDays,
            totalDays: totalDays,
            percentageCompleted: percentageCompleted,
            gradientName: self.gradientName ?? "PinkPurple",
            title: self.title ?? ""
        )
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let primaryData: DateEntityData
    let secondaryData: DateEntityData?
    let viewStyle: ViewStyle
}

struct RemainingWidget: Widget {
    let kind: String = "RemainingWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider(container: PersistenceController.shared.container)) { entry in
            if entry.viewStyle == .singleProgressBar {
                SingleProgressBarEntryView(entry: entry)
            } else {
                DoubleProgressBarEntryView(entry: entry)
            }
        }
    }
}

struct SingleProgressBarPreview: PreviewProvider {
    static var previews: some View {
        SingleProgressBarEntryView(entry: SimpleEntry(
            date: Date(),
            primaryData: DateEntityData(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                remainingDays: 347,
                completedDays: 533,
                totalDays: 10,
                percentageCompleted: 30,
                gradientName: "PinkPurple",
                title: "Primary Event"
            ),
            secondaryData: nil,
            viewStyle: .singleProgressBar
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}



extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        _ = scanner.scanString("#")
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
