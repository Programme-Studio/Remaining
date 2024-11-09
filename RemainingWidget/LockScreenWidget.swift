import WidgetKit
import SwiftUI
import CoreData

struct LockScreenProvider: AppIntentTimelineProvider {
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

struct LockScreenEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color(hex: "#EAEAEA").opacity(0.2), // Light grey background with 0.2 opacity
                    lineWidth: 6
                )
                .frame(width: 50, height: 50)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(entry.primaryData.percentageCompleted / 100))
                .stroke(
                    Color.white.opacity(1), // Solid color stroke with 0.8 opacity
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
                .frame(width: 50, height: 50)
            
            Text("\(Int(entry.primaryData.percentageCompleted))%")
                .font(.system(size: 15, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding()
        .containerBackground(for: .widget) {
            Color.clear // Transparent background
        }
        .clipShape(Circle())
    }
}

struct LockScreenWidget: Widget {
    let kind: String = "LockScreenWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: LockScreenProvider(container: PersistenceController.shared.container)) { entry in
            LockScreenEntryView(entry: entry)
        }
        .configurationDisplayName("Lock Screen Widget")
        .description("Shows the percentage completed with a circular progress bar.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenWidget_Previews: PreviewProvider {
    static var previews: some View {
        let provider = LockScreenProvider(container: PersistenceController.preview.container)
        let data = provider.fetchDateData()
        let entry = SimpleEntry(date: .now, primaryData: data.primaryData, secondaryData: data.secondaryData, viewStyle: .singleProgressBar)

        LockScreenEntryView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
    }
}
