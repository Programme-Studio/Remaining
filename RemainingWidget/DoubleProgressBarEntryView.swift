import SwiftUI
import WidgetKit

struct DoubleProgressBarEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(spacing: 2) { // Reduced spacing here
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: -4) {
                    Text(dayFormatter.string(from: entry.date))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(dayNumberFormatter.string(from: entry.date))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: -4) {
                    HStack(spacing: 6) {
                        Text("→")
                        Text("\(entry.primaryData.remainingDays)")
                    }
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .kerning(-1)

                    HStack(spacing: 6) {
                        Text("←")
                            .padding(.leading, -2)
                        Text("\(entry.primaryData.completedDays)")
                    }
                    .font(.system(size: 20, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(hex: "#6C6C6C"))
                    .kerning(-1)
                }
            }

            VStack(spacing: 6) { // Increased spacing between progress bars
                progressBarView(data: entry.primaryData)
                if let secondaryData = entry.secondaryData {
                    progressBarView(data: secondaryData)
                }
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "#292929")
        }
    }

    private func progressBarView(data: DateEntityData) -> some View {
        VStack(spacing: 3) {
            Text(data.title)
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundColor(Color(hex: "#6C6C6C"))
                .frame(maxWidth: .infinity, alignment: .leading)
            
            ZStack {
                // Background
                Capsule()
                    .fill(Color(hex: "#535252"))
                    .frame(height: 23)
                
                // Progress with mask
                Capsule()
                    .fill(GradientOption.gradient(for: data.gradientName))
                    .frame(height: 23)
                    .mask(
                        GeometryReader { geometry in
                            HStack(spacing: 0) {
                                Rectangle()
                                    .frame(width: geometry.size.width * CGFloat(data.percentageCompleted / 100))
                                Rectangle()
                                    .fill(.clear)
                            }
                        }
                    )
                
                GeometryReader { progressGeometry in
                    let progressWidth = CGFloat(data.percentageCompleted / 100) * progressGeometry.size.width
                    let percentageCompleted = Int(data.percentageCompleted)
                    let percentageLeft = 100 - percentageCompleted
                    let remainingWidth = progressGeometry.size.width - progressWidth

                    if percentageCompleted >= 75 {
                        // When progress is ≥75%, show both percentages together in filled section
                        HStack(spacing: 2) {
                            Text("\(percentageCompleted)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                            Text("/")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(0.5)
                            Text("\(percentageLeft)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(0.5)
                        }
                        .frame(width: progressWidth, height: progressGeometry.size.height, alignment: .center)
                    } else if percentageCompleted <= 20 {
                        // When progress is ≤20%, show both percentages together in unfilled section
                        HStack(spacing: 2) {
                            Text("\(percentageCompleted)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(0.5)
                            Text("/")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .opacity(0.5)
                            Text("\(percentageLeft)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        .frame(width: remainingWidth, height: progressGeometry.size.height, alignment: .center)
                        .offset(x: progressWidth)
                    } else {
                        // Normal state (20% < progress < 75%)
                        HStack(spacing: 0) {
                            Text("\(percentageCompleted)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(width: progressWidth, height: progressGeometry.size.height, alignment: .center)
                            
                            Text("\(percentageLeft)%")
                                .font(.system(size: 12, weight: .regular, design: .monospaced))
                                .foregroundColor(.white)
                                .frame(width: remainingWidth, height: progressGeometry.size.height, alignment: .center)
                        }
                    }
                }
            }
            .frame(height: 23)
        }
    }

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
        formatter.dateFormat = "d"
        return formatter
    }
}

struct DoubleProgressBarEntryView_Previews: PreviewProvider {
    static var previews: some View {
        DoubleProgressBarEntryView(entry: SimpleEntry(
            date: Date(),
            primaryData: DateEntityData(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                remainingDays: 298,
                completedDays: 3,
                totalDays: 10,
                percentageCompleted: 30,
                gradientName: "PinkPurple",
                title: "Primary Event"
            ),
            secondaryData: DateEntityData(
                startDate: Date(),
                endDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                remainingDays: 2,
                completedDays: 3,
                totalDays: 5,
                percentageCompleted: 10,
                gradientName: "BlueGreen",
                title: "Secondary Event"
            ),
            viewStyle: .doubleProgressBar
        ))
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
