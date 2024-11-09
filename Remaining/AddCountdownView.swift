import SwiftUI
import CoreData
import WidgetKit

struct AddCountdownView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode

    @State private var title: String = ""
    @State private var eventStart: Date = Date()
    @State private var eventEnd: Date = Date()
    @State private var isWidgetSelected: Bool = false
    @State private var secondWidgetSelected: Bool = false
    @State private var selectedGradient: GradientOption? = GradientOption.options.first

    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            List {
                Section(header: Text("Title")) {
                    TextField("Title", text: $title)
                }
                Section(header: Text("dates")) {
                    DatePicker("Start Date", selection: $eventStart, displayedComponents: .date)
                    DatePicker("End Date", selection: $eventEnd, displayedComponents: .date)
                }
                Section(header: Text("widget options")) {
                    Toggle("Single Widget", isOn: $isWidgetSelected)
                    Toggle("Double Widget", isOn: $secondWidgetSelected)
                }
                Section(header: Text("Progress bar colour options")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            ForEach(GradientOption.options) { option in
                                Circle()
                                    .fill(option.gradient)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Circle()
                                            .stroke(selectedGradient == option ? Color.blue : Color.clear, lineWidth: 3)
                                            .frame(width: 56, height: 56) // Slightly larger frame for the stroke
                                    )
                                    .onTapGesture {
                                        selectedGradient = option
                                    }
                                    .padding(.vertical, 5)
                            }
                        }
                        .padding(.horizontal, 5)
                    }
                    .padding(.vertical, 5)
                }
                .listStyle(GroupedListStyle())
            }
            .navigationBarBackButtonHidden(true)
            .navigationTitle("New Countdown")
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
                    addCountdown()
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Add")
                        .foregroundColor(Color.blue)
                }
            )
        }
    }

    private func addCountdown() {
        if isWidgetSelected {
            deselectOtherWidgets(for: \.isWidgetSelected)
        }
        if secondWidgetSelected {
            deselectOtherWidgets(for: \.secondWidgetSelected)
        }

        let newCountdown = DateEntity(context: viewContext)
        newCountdown.title = title
        newCountdown.eventStart = eventStart
        newCountdown.eventEnd = eventEnd
        newCountdown.isWidgetSelected = isWidgetSelected
        newCountdown.secondWidgetSelected = secondWidgetSelected
        newCountdown.gradientName = selectedGradient?.name ?? "PinkPurple"

        // Fetch the maximum order value from the context
        let fetchRequest: NSFetchRequest<DateEntity> = DateEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \DateEntity.order, ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            let maxOrder = results.first?.order ?? 0
            newCountdown.order = maxOrder + 1

            try viewContext.save()
            print("Event added: \(newCountdown)") // Debug print
            WidgetCenter.shared.reloadAllTimelines() // Ensure the widget is reloaded
        } catch {
            // Handle the Core Data error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }

    private func deselectOtherWidgets(for keyPath: ReferenceWritableKeyPath<DateEntity, Bool>) {
        let fetchRequest: NSFetchRequest<DateEntity> = DateEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "%K == true", NSExpression(forKeyPath: keyPath).keyPath)

        do {
            let results = try viewContext.fetch(fetchRequest)
            for countdown in results {
                countdown[keyPath: keyPath] = false
            }
        } catch {
            // Handle the Core Data error appropriately.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct AddCountdownView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return NavigationStack {
            AddCountdownView()
                .environment(\.managedObjectContext, context)
        }
    }
}
