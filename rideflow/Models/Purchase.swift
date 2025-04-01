import CoreData

@objc(Purchase)
public class Purchase: NSManagedObject {
    @NSManaged @objc public var productId: String
    @NSManaged @objc public var transactionId: String
    @NSManaged @objc public var purchaseDate: Date
}

// 保持现有的扩展
extension Purchase {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Purchase> {
        return NSFetchRequest<Purchase>(entityName: "Purchase")
    }
}
