import CoreData


extension Purchase {
    static func create(productId: String, transactionId: String, context: NSManagedObjectContext) -> Purchase {
        let purchase = Purchase(context: context)
        purchase.productId = productId
        purchase.transactionId = transactionId
        purchase.purchaseDate = Date()
        return purchase
    }
}
