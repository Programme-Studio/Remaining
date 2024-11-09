import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext

        // Add mock data for preview
        let dateEntity = DateEntity(context: viewContext)
        dateEntity.eventStart = Calendar.current.date(byAdding: .day, value: -95, to: Date())
        dateEntity.eventEnd = Calendar.current.date(byAdding: .day, value: 324, to: dateEntity.eventStart!)
        dateEntity.title = "Sample Event"
        dateEntity.isWidgetSelected = true

        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }

        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Remaining")

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Use App Group container for shared data
            if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.programme.remaining") {
                let storeURL = appGroupURL.appendingPathComponent("Remaining.sqlite")
                let description = NSPersistentStoreDescription(url: storeURL)
                container.persistentStoreDescriptions = [description]
            } else {
                // Fallback to in-memory store if app group container is not accessible
                // Log the error instead of crashing
                print("Unable to access app group container")
                container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            }
        }

        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Handle the error appropriately in a production app
                print("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
