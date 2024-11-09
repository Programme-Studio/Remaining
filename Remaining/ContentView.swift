import SwiftUI
import CoreData
import Combine
import Charts

struct GradientProgressViewStyle: ProgressViewStyle {
    let gradient: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        ZStack(alignment: .leading) {
            Capsule()
                .foregroundColor(Color(hex: "#EAEAEA"))
                .frame(height: 30)
            GeometryReader { geometry in
                let progressWidth = CGFloat(configuration.fractionCompleted ?? 0) * geometry.size.width
                let percentageCompleted = Int((configuration.fractionCompleted ?? 0) * 100)
                let percentageLeft = 100 - percentageCompleted
                
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(gradient)
                        .frame(width: progressWidth, height: 30)
                    if percentageCompleted > 8 {
                        Text("\(percentageCompleted)%")
                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                            .foregroundColor(.white)
                            .frame(width: progressWidth, alignment: .center)
                    }
                }
                .frame(height: 30)
                
                ZStack(alignment: .trailing) {
                    Text("\(percentageLeft)%")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(hex: "#878787"))
                        .frame(width: geometry.size.width - progressWidth, alignment: .center)
                        .offset(x: progressWidth)
                }
                .frame(height: 30)
            }
        }
    }
}

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.order, ascending: true)],
        animation: .default)
    private var countdowns: FetchedResults<DateEntity>
    
    @State private var editMode = EditMode.inactive
    @State private var activeCountdown: DateEntity?
    @State private var isEditViewActive = false
    private var cancellable: AnyCancellable?
    
    var body: some View {
        NavigationView {
            Group {
                if countdowns.isEmpty {
                    VStack {
                        Spacer()
                        Text("Click the 'Add' button in the top right corner to create a new countdown")
                            .font(.system(size: 24, weight: .regular, design: .rounded))
                            .foregroundColor(Color.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40.0)
                            .padding(.vertical, -40.0)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack {
                        CountdownChartView(countdowns: countdowns)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 3)
                            .padding(.top, 8)// Reduce padding from the bottom
                        List {
                            ForEach(countdowns) { countdown in
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(alignment: .top) {
                                        VStack(alignment: .leading, spacing: -5) {
                                            Text(countdown.title ?? "Untitled")
                                                .font(.system(size: 28, weight: .semibold, design: .rounded))
                                                .foregroundColor(.black)
                                            
                                            if countdown.isWidgetSelected {
                                                Image(systemName: "gauge.open.with.lines.needle.33percent.and.arrowtriangle")
                                                    .font(.system(size: 28, weight: .regular, design: .rounded))
                                                    .foregroundColor(.gray)
                                                    .padding(.top, 5)
                                            }
                                            
                                            if countdown.secondWidgetSelected {
                                                Image(systemName: "gauge.open.with.lines.needle.67percent.and.arrowtriangle")
                                                    .font(.system(size: 28, weight: .regular, design: .rounded))
                                                    .foregroundColor(.gray)
                                                    .padding(.top, 5)
                                            }
                                        }
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: -5) {
                                            HStack(spacing: 4) {
                                                Text("→")
                                                Text("\(countdown.daysLeft())")
                                            }
                                            .font(.system(size: 28, weight: .regular, design: .monospaced))
                                            .foregroundColor(.black)
                                            
                                            HStack(spacing: 6) {
                                                Text("←")
                                                    .padding(.leading, -2)
                                                Text("\(countdown.daysCompleted())")
                                            }
                                            .font(.system(size: 28, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#878787"))
                                        }
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("0")
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#878787"))
                                        Spacer()
                                        Text("\(countdown.daysCompleted() + countdown.daysLeft())")
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#878787"))
                                    }
                                    .padding(.bottom, -3)
                                    ProgressView(value: countdown.completionPercentage(), total: 100)
                                        .progressViewStyle(GradientProgressViewStyle(
                                            gradient: GradientOption.gradient(for: countdown.gradientName ?? "PinkPurple")
                                        ))
                                        .frame(height: 30)
                                        .cornerRadius(5)
                                    HStack(spacing: 4) {
                                        Text("\(startDateString(for: countdown))")
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#878787"))
                                        Spacer()
                                        Text("\(endDateString(for: countdown))")
                                            .font(.system(size: 12, weight: .regular, design: .monospaced))
                                            .foregroundColor(Color(hex: "#878787"))
                                    }
                                }
                                .padding()
                                .background(
                                    colorScheme == .dark ? Color(hex: "#D3D3D3") : Color(hex: "#F8F8F8")
                                )
                                .cornerRadius(10)
                                .background(
                                    NavigationLink(destination: EditCountdownView(countdown: countdown)) {
                                        EmptyView()
                                    }
                                        .opacity(editMode == .active ? 1 : 0)
                                )
                                .contentShape(Rectangle())
                                .listRowSeparator(.hidden)
                            }
                            .onMove(perform: moveItems)
                        }
                        .listStyle(PlainListStyle())
                    }
                }
            }
            .background(Color.clear)
            .onAppear {
                UITableView.appearance().separatorStyle = .none
                UITableView.appearance().backgroundColor = UIColor.clear
                UITableViewCell.appearance().backgroundColor = UIColor.clear
                refreshCountdowns()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        withAnimation {
                            editMode = editMode == .active ? .inactive : .active
                        }
                    }) {
                        Text(editMode == .active ? "Done" : "Reorder")
                    }
                    .foregroundColor(Color(hex: "#878787"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("Add") {
                        AddCountdownView()
                    }
                    .foregroundColor(Color(hex: "#878787"))
                }
            }
            .environment(\.editMode, $editMode)
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        var revisedItems = countdowns.map { $0 }
        revisedItems.move(fromOffsets: source, toOffset: destination)
        
        for (index, item) in revisedItems.enumerated() {
            item.order = Int16(index)
        }
        
        do {
            try viewContext.save()
            print("Order updated successfully")
        } catch {
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    private func startDateString(for countdown: DateEntity) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: countdown.eventStart ?? Date())
    }
    
    private func endDateString(for countdown: DateEntity) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        formatter.timeZone = TimeZone.current
        return formatter.string(from: countdown.eventEnd ?? Date())
    }
    
    private func refreshCountdowns() {
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            withAnimation {
                self.viewContext.refreshAllObjects()
                do {
                    try self.viewContext.save()
                    print("Data refreshed on app becoming active")
                } catch {
                    print("Failed to refresh data: \(error)")
                }
            }
        }
    }
}

struct CountdownChartView: View {
    var countdowns: FetchedResults<DateEntity>
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy" // Change the format as needed
        return formatter.string(from: date)
    }
    
    var body: some View {
        let minStartDate = countdowns.map { $0.eventStart ?? Date() }.min() ?? Date()
        let maxEndDate = countdowns.map { $0.eventEnd ?? Date() }.max() ?? Date()
        
        let barHeight: CGFloat = 40
        let chartHeight = barHeight * CGFloat(countdowns.count)
        
        let monthDividers = generateMonthDividers(from: minStartDate, to: maxEndDate)
        
        return Chart {
            ForEach(countdowns) { countdown in
                let startDate = countdown.eventStart ?? Date()
                let endDate = countdown.eventEnd ?? Date()
                let gradient = GradientOption.gradient(for: countdown.gradientName ?? "PinkPurple")
                BarMark(
                    xStart: .value("Start", startDate),
                    xEnd: .value("End", endDate),
                    y: .value("Countdown", countdown.title ?? "Untitled")
                )
                .foregroundStyle(gradient)
                .cornerRadius(10)
                .annotation(position: .overlay) {
                    CountdownAnnotationView(title: countdown.title)
                }
            }
            
            RuleMark(x: .value("Today", Date()))
                .lineStyle(StrokeStyle(lineWidth: 2))
                .foregroundStyle(Color.red)
                .annotation(position: .top, alignment: .leading) {
                    Text(formatDate(Date()))
                        .font(.caption)
                        .foregroundColor(.red)
                }
        }
        .chartXAxis {
            AxisMarks(values: monthDividers) { value in
                AxisGridLine(centered: true, stroke: StrokeStyle(lineWidth: 0.6, dash: [2, 1.95]))
                    .foregroundStyle(Color(hex: "#CECED0")) // Change the dotted line color
                AxisTick(centered: true)
                AxisValueLabel(centered: true) {
                    if let dateValue = value.as(Date.self) {
                        Text(formatMonth(dateValue))
                    }
                }
            }
        }
        .chartYAxis {
            
        }
        .frame(height: chartHeight)
        .onAppear {
            print("Min start date: \(minStartDate)")
            print("Max end date: \(maxEndDate)")
            print("Generated month dividers:")
            monthDividers.forEach { date in
                print(date)
            }
        }
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        let monthString = formatter.string(from: date)
        return String(monthString.prefix(1)) // Show only the first letter
    }
    
    private func generateMonthDividers(from startDate: Date, to endDate: Date) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current
        
        // Align start date to the first day of the start month
        let startComponents = calendar.dateComponents([.year, .month], from: startDate)
        let alignedStartDate = calendar.date(from: startComponents)!
        
        // Align end date to the last day of the end month
        let endComponents = calendar.dateComponents([.year, .month], from: endDate)
        let alignedEndDate = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: calendar.date(from: endComponents)!)!
        
        // Generate dates for the first day of each month between start and end dates
        var currentDate = alignedStartDate
        while currentDate <= alignedEndDate {
            dates.append(currentDate)
            currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate)!
        }
        
        // Add the end date to the list if it is not already included
        if !calendar.isDate(currentDate, inSameDayAs: alignedEndDate) {
            dates.append(alignedEndDate)
        }
        
        return dates
    }
}

struct CountdownAnnotationView: View {
    var title: String?
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Text(title ?? "Untitled")
                    .font(.system(size: 12, weight: .regular, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.leading, 5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            Spacer()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
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
