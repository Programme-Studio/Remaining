import SwiftUI
import CoreData
import WidgetKit

struct EditCountdownView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var countdown: DateEntity

    @State private var title: String = ""
    @State private var eventStart: Date = Date()
    @State private var eventEnd: Date = Date()
    @State private var isWidgetSelected: Bool = false
    @State private var secondWidgetSelected: Bool = false
    @State private var selectedGradient: GradientOption? = GradientOption.options.first

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \DateEntity.eventEnd, ascending: true)],
        animation: .default)
    private var countdowns: FetchedResults<DateEntity>

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            List {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                        .onChange(of: title) { newValue in
                            saveChanges()
                        }
                }
                Section(header: Text("Dates")) {
                    DatePicker("Start Date", selection: $eventStart, displayedComponents: .date)
                        .onChange(of: eventStart) { newValue in
                            saveChanges()
                        }
                    DatePicker("End Date", selection: $eventEnd, displayedComponents: .date)
                        .onChange(of: eventEnd) { newValue in
                            saveChanges()
                        }
                }
                Section(header: Text("Widget Options")) {
                    Toggle("Single Widget", isOn: $isWidgetSelected)
                        .onChange(of: isWidgetSelected) { newValue in
                            saveChanges()
                        }
                    Toggle("Double Widget", isOn: $secondWidgetSelected)
                        .onChange(of: secondWidgetSelected) { newValue in
                            saveChanges()
                        }
                }
                Section(header: Text("Progress Bar Colour Options")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(GradientOption.options) { option in
                                Circle()
                                    .fill(option.gradient)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedGradient == option ? Color.blue : Color.clear, lineWidth: 3)
                                            .frame(width: 56, height: 56)
                                    )
                                    .onTapGesture {
                                        selectedGradient = option
                                        saveChanges()
                                    }
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.vertical, 5)
                }
                Section {
                    Button(action: {
                        deleteCountdown()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Delete")
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    .listRowInsets(EdgeInsets())
                }
                .listStyle(GroupedListStyle())
            }
            .onAppear {
                self.title = countdown.title ?? ""
                self.eventStart = countdown.eventStart ?? Date()
                self.eventEnd = countdown.eventEnd ?? Date()
                self.isWidgetSelected = countdown.isWidgetSelected
                self.secondWidgetSelected = countdown.secondWidgetSelected
                self.selectedGradient = GradientOption.options.first { $0.name == countdown.gradientName }
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("Edit Countdown")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .foregroundColor(Color(hex: "#878787"))
                            .imageScale(.large)
                        Text("Back")
                            .foregroundColor(Color(hex: "#878787"))
                    }
                },
                trailing: Button(action: {
                    saveChanges()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Save")
                        .foregroundColor(Color.blue)
                }
            )
        }
    }

    private func saveChanges() {
        if isWidgetSelected {
            deselectOtherWidgets(for: \.isWidgetSelected)
        }
        if secondWidgetSelected {
            deselectOtherWidgets(for: \.secondWidgetSelected)
        }

        countdown.title = title
        countdown.eventStart = eventStart
        countdown.eventEnd = eventEnd
        countdown.isWidgetSelected = isWidgetSelected
        countdown.secondWidgetSelected = secondWidgetSelected
        countdown.gradientName = selectedGradient?.name ?? "PinkPurple"

        do {
            try viewContext.save()
            print("Event edited: \(countdown)") // Debug print
            WidgetCenter.shared.reloadAllTimelines() // Ensure the widget is reloaded
        } catch {
            // Handle the Core Data error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deleteCountdown() {
        viewContext.delete(countdown)

        do {
            try viewContext.save()
            print("Event deleted: \(countdown)") // Debug print
            WidgetCenter.shared.reloadAllTimelines() // Ensure the widget is reloaded
        } catch {
            // Handle the Core Data error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deselectOtherWidgets(for keyPath: ReferenceWritableKeyPath<DateEntity, Bool>) {
        for countdown in countdowns {
            if countdown != self.countdown {
                countdown[keyPath: keyPath] = false
            }
        }
    }
}

struct EditCountdownView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let countdown = DateEntity(context: context)
        countdown.title = "Sample Countdown"
        countdown.eventStart = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        countdown.eventEnd = Calendar.current.date(byAdding: .day, value: 10, to: Date())
        countdown.isWidgetSelected = true
        countdown.secondWidgetSelected = true

        return NavigationStack {
            EditCountdownView(countdown: countdown)
                .environment(\.managedObjectContext, context)
        }
    }
}
