import UIKit
import BackgroundTasks
import CoreData

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    // This function is called when the app finishes launching. It registers a background task for app refresh.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("Application did finish launching")
        
        // Registering a background task with the identifier "com.programme.app.refresh".
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "com.programme.app.refresh", using: nil) { task in
            // Handle the background refresh task when it is scheduled to run.
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
        // Schedule the app refresh task.
        scheduleAppRefresh()
        return true
    }

    // This function handles the background app refresh task.
    func handleAppRefresh(task: BGAppRefreshTask) {
        print("Handling app refresh task at \(Date())")
        
        // Schedule the next refresh task.
        scheduleAppRefresh()

        // Define an expiration handler in case the task runs too long.
        task.expirationHandler = {
            // If the task expires, mark it as incomplete.
            task.setTaskCompleted(success: false)
            print("Task expired")
        }

        // Perform the background update of countdowns.
        updateCountdowns { success in
            // Mark the task as completed with a success flag.
            task.setTaskCompleted(success: success)
            print("Task completed with success: \(success)")
        }
    }

    // This function schedules the app refresh task to run just after midnight.
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "com.programme.app.refresh")
        
        // Schedule the task to start just after midnight.
        if let nextMidnight = Calendar.current.nextDate(after: Date(), matching: DateComponents(hour: 0, minute: 0), matchingPolicy: .nextTime) {
            request.earliestBeginDate = nextMidnight.addingTimeInterval(120) // Adding a 2-minute buffer to ensure it runs after midnight.
        }

        do {
            // Submit the background task request to the scheduler.
            try BGTaskScheduler.shared.submit(request)
            print("Scheduled app refresh for \(request.earliestBeginDate?.description ?? "unknown time")")
        } catch let error as NSError {
            // Handle errors if the task scheduling fails.
            print("Could not schedule app refresh: \(error.localizedDescription), \(error.userInfo)")
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("Underlying error: \(underlyingError.localizedDescription), \(underlyingError.userInfo)")
            }
        }
    }

    // This function updates countdown entities in Core Data without changing the start and end dates.
    func updateCountdowns(completion: @escaping (Bool) -> Void) {
        let context = PersistenceController.shared.container.viewContext
        let fetchRequest: NSFetchRequest<DateEntity> = DateEntity.fetchRequest()

        do {
            // Fetch the current countdown entities from the context.
            let results = try context.fetch(fetchRequest)
            
            for entity in results {
                // Refresh each entity to ensure calculated fields (e.g., days remaining) are updated without altering the dates.
                context.refresh(entity, mergeChanges: true)
            }
            
            // Save the updated context.
            try context.save()
            completion(true)
        } catch {
            // Handle errors if fetching or saving the context fails.
            print("Failed to fetch or save context: \(error)")
            completion(false)
        }
    }
}
