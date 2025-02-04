import SwiftUI
import WidgetKit

struct SingleProgressBarEntryView: View {
   @Environment(\.widgetFamily) var family
   var entry: SimpleEntry

   private var formattedDate: DateFormatter {
       let formatter = DateFormatter()
       formatter.dateFormat = "dd.MM"
       return formatter
   }

   private var dayFormatter: DateFormatter {
       let formatter = DateFormatter()
       formatter.dateFormat = "E"
       return formatter
   }

   private var dayNumberFormatter: DateFormatter {
       let formatter = DateFormatter()
       formatter.dateFormat = "dd"
       return formatter
   }

   private func getFontSize() -> CGFloat {
       switch family {
       case .systemSmall:
           return 25
       case .systemMedium:
           return 30
       case .systemLarge:
           return 45
       default:
           return 25
       }
   }

   private func getProgressBarHeight() -> CGFloat {
       switch family {
       case .systemSmall:
           return 30
       case .systemMedium:
           return 35
       case .systemLarge:
           return 45
       default:
           return 30
       }
   }

   private func getSecondaryFontSize() -> CGFloat {
       switch family {
       case .systemSmall:
           return 12
       case .systemMedium:
           return 14
       case .systemLarge:
           return 18
       default:
           return 12
       }
   }

   var body: some View {
       GeometryReader { geometry in
           VStack(spacing: 0) {
               // Top Section
               HStack(alignment: .top) {
                   VStack(alignment: .leading, spacing: -4) {
                       Text(dayFormatter.string(from: entry.date))
                           .font(.system(size: getFontSize(), weight: .bold, design: .rounded))
                           .foregroundColor(.white)
                           .lineLimit(1)

                       Text(dayNumberFormatter.string(from: entry.date))
                           .font(.system(size: getFontSize(), weight: .bold, design: .rounded))
                           .foregroundColor(.white)
                           .lineLimit(1)
                   }
                   
                   Spacer()
                   
                   VStack(alignment: .trailing, spacing: -4) {
                       HStack(spacing: 2) {
                           Text("→")
                           Text("\(entry.primaryData.remainingDays)")
                       }
                       .font(.system(size: getFontSize(), weight: .regular, design: .monospaced))
                       .foregroundColor(.white)
                       .kerning(-1)
                       .lineLimit(1)

                       HStack(spacing: 2) {
                           Text("←")
                               .padding(.leading, -2)
                           Text("\(entry.primaryData.completedDays)")
                       }
                       .font(.system(size: getFontSize(), weight: .regular, design: .monospaced))
                       .foregroundColor(Color(hex: "#6C6C6C"))
                       .kerning(-1)
                       .lineLimit(1)
                   }
               }
               .padding(.top, -6)
               
               Spacer()
               
               // Progress Bar Section
               VStack(spacing: geometry.size.height * 0.01) {
                   HStack(spacing: 0) {
                       Text("0")
                       
                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                           .foregroundColor(Color(hex: "#6C6C6C"))
                       Spacer()
                       Text("\(entry.primaryData.totalDays)")
                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                           .foregroundColor(Color(hex: "#6C6C6C"))
                   }
                   
                   ZStack {
                       Capsule()
                           .frame(height: getProgressBarHeight())
                           .foregroundColor(Color(hex: "#535252"))
                       GeometryReader { progressGeometry in
                           let progressWidth = CGFloat(entry.primaryData.percentageCompleted / 100) * progressGeometry.size.width
                           let percentageCompleted = Int(entry.primaryData.percentageCompleted)
                           let percentageLeft = 100 - percentageCompleted
                           let remainingWidth = progressGeometry.size.width - progressWidth

                           ZStack(alignment: .leading) {
                               // Background progress bar
                               Capsule()
                                   .fill(GradientOption.gradient(for: entry.primaryData.gradientName))
                                   .frame(width: progressWidth, height: getProgressBarHeight())
                               
                               if percentageCompleted >= 75 {
                                   // When progress is ≥75%, show both percentages together in filled section
                                   HStack(spacing: 2) {
                                       Text("\(percentageCompleted)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                       Text("/")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .opacity(0.5)
                                       Text("\(percentageLeft)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .opacity(0.5)
                                   }
                                   .frame(width: progressWidth, alignment: .center)
                               } else if percentageCompleted <= 20 {
                                   // When progress is ≤20%, show both percentages together in unfilled section
                                   HStack(spacing: 2) {
                                       Text("\(percentageCompleted)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .opacity(0.5)
                                       Text("/")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .opacity(0.5)
                                       Text("\(percentageLeft)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                   }
                                   .frame(width: remainingWidth, alignment: .center)
                                   .offset(x: progressWidth)
                               } else {
                                   // Normal state (20% < progress < 75%)
                                   HStack(spacing: 0) {
                                       Text("\(percentageCompleted)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .frame(width: progressWidth)
                                       
                                       Text("\(percentageLeft)%")
                                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                                           .foregroundColor(.white)
                                           .frame(width: remainingWidth)
                                   }
                               }
                           }
                       }
                   }
                   .frame(height: getProgressBarHeight())
                   
                   HStack {
                       Text(formattedDate.string(from: entry.primaryData.startDate))
                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                           .foregroundColor(Color(hex: "#6C6C6C"))
                       Spacer()
                       Text(formattedDate.string(from: entry.primaryData.endDate))
                           .font(.system(size: getSecondaryFontSize(), weight: .regular, design: .monospaced))
                           .foregroundColor(Color(hex: "#6C6C6C"))
                   }
               }
           }
       }
       .containerBackground(for: .widget) {
           Color(hex: "#292929")
       }
   }
}

#if DEBUG
struct SingleProgressBarEntryView_Previews: PreviewProvider {
   static var previews: some View {
       Group {
           SingleProgressBarEntryView(entry: SimpleEntry(
               date: Date(),
               primaryData: DateEntityData(
                   startDate: Date(),
                   endDate: Calendar.current.date(byAdding: .day, value: 365, to: Date())!,
                   remainingDays: 347,
                   completedDays: 18,
                   totalDays: 365,
                   percentageCompleted: 10,
                   gradientName: "PinkPurple",
                   title: "Primary Event"
               ),
               secondaryData: nil,
               viewStyle: .singleProgressBar
           ))
           .previewContext(WidgetPreviewContext(family: .systemSmall))
           .containerBackground(.black, for: .widget)
           .previewDisplayName("Small Widget")
           
           SingleProgressBarEntryView(entry: SimpleEntry(
               date: Date(),
               primaryData: DateEntityData(
                   startDate: Date(),
                   endDate: Calendar.current.date(byAdding: .day, value: 365, to: Date())!,
                   remainingDays: 347,
                   completedDays: 18,
                   totalDays: 365,
                   percentageCompleted: 10,
                   gradientName: "PinkPurple",
                   title: "Primary Event"
               ),
               secondaryData: nil,
               viewStyle: .singleProgressBar
           ))
           .previewContext(WidgetPreviewContext(family: .systemMedium))
           .containerBackground(.black, for: .widget)
           .previewDisplayName("Medium Widget")
           
           SingleProgressBarEntryView(entry: SimpleEntry(
               date: Date(),
               primaryData: DateEntityData(
                   startDate: Date(),
                   endDate: Calendar.current.date(byAdding: .day, value: 365, to: Date())!,
                   remainingDays: 347,
                   completedDays: 18,
                   totalDays: 365,
                   percentageCompleted: 10,
                   gradientName: "PinkPurple",
                   title: "Primary Event"
               ),
               secondaryData: nil,
               viewStyle: .singleProgressBar
           ))
           .previewContext(WidgetPreviewContext(family: .systemLarge))
           .containerBackground(.black, for: .widget)
           .previewDisplayName("Large Widget")
       }
   }
}
#endif
