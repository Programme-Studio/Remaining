import Foundation
import CoreData

extension DateEntity: Identifiable {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DateEntity> {
        return NSFetchRequest<DateEntity>(entityName: "DateEntity")
    }

    @NSManaged public var eventStart: Date?
    @NSManaged public var eventEnd: Date?
    @NSManaged public var title: String?
    @NSManaged public var gradientName: String?
    @NSManaged public var isWidgetSelected: Bool
    @NSManaged public var secondWidgetSelected: Bool
    @NSManaged public var order: Int16
}
