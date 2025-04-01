import Combine
import CoreData
import Foundation
import CoreLocation
import CoreDataStorage

extension CoreDataStorage {
    func update(_ block: @escaping (NSManagedObjectContext) -> Void) {
        _ = self.performInBackgroundAndSave { block($0) }
    }
    
    func isPurchaseRecordExists(productId: String) -> Bool {
        let request: NSFetchRequest<Purchase> = Purchase.fetchRequest()
        request.predicate = NSPredicate(format: "productId == %@", productId)
        
        do {
            let count = try mainContext.count(for: request)
            return count > 0
        } catch {
            return false
        }
    }

    // 添加获取所有购买记录的方法
    func getAllPurchaseRecords() -> [Purchase] {
        let request: NSFetchRequest<Purchase> = Purchase.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Purchase.purchaseDate, ascending: false)]
        
        do {
            return try mainContext.fetch(request)
        } catch {
            return []
        }
    }

    // 添加删除购买记录的方法
    func deletePurchaseRecord(productId: String) -> Bool {
        let request: NSFetchRequest<Purchase> = Purchase.fetchRequest()
        request.predicate = NSPredicate(format: "productId == %@", productId)
        
        do {
            let purchases = try mainContext.fetch(request)
            for purchase in purchases {
                mainContext.delete(purchase)
            }
            try mainContext.save()
            return true
        } catch {
            return false
        }
    }
    
    // Add performBackgroundTask method
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            performInBackgroundAndSave { context in
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // 在后台线程上执行操作
    func performInBackgroundAndSave(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = self.backgroundContext
        context.perform {
            block(context)
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    // 处理保存错误
                    print("Failed to save context: \(error)")
                }
            }
        }
    }
}

class StorageService: Service {
    
    // 单例实现
    static let shared = StorageService()

    let shouldAutostart = true
    //let storage = CoreDataStorage(container: try! NSPersistentContainer("Velik"))
    private(set) var storage: CoreDataStorage
    // 私有初始化方法，防止外部创建实例
   private init() {
       self.storage = CoreDataStorage(container: try! NSPersistentContainer("Velik"))
   }
   
   // 提供获取 CoreDataStorage 的方法
   static func getStorage() -> CoreDataStorage {
       return shared.storage
   }

    func start() {
        debugPrint(storage)
    }

    func stop() { }

    func createNewRide(name: String, summary: Summary, locations: [CLLocation], createdAt: Date? = nil) {
        storage.update { context in
            let ride = Ride.create(name: name, context: context)
            if let createdAt = createdAt {
                ride.createdAt = createdAt
            }
            // Summary
            // 确保创建 RideSummary 并正确关联
            let newSummary = RideSummary.create(context: context)
            newSummary.distance = summary.distance
            newSummary.duration = summary.duration
            newSummary.avgSpeed = summary.avgSpeed
            newSummary.maxSpeed = summary.maxSpeed
            newSummary.elevationGain = summary.elevationGain
            // 建立双向关联
            ride.summary = newSummary
            newSummary.ride = ride
            // Track
            ride.track = Track.create(name: name, context: context)
            locations
                .forEach { ride.track?.addTrackPoint(with: $0, context: context) }
            locations
                .region()
                .map { ride.track?.region = TrackRegion.create(region: $0, context: context) }
        }
    }
    


    func deleteRide(objectID: NSManagedObjectID) {
        storage.update { context in
            context.delete(context.object(with: objectID))
        }
    }
    
    
    // 在主线程上执行操作
    private func performOnMainContext(_ block: @escaping (NSManagedObjectContext) -> Void) {
        let context = storage.mainContext
        if Thread.isMainThread {
            block(context)
        } else {
            DispatchQueue.main.async {
                block(context)
            }
        }
    }

    enum StorageError: Error {
        case itemNotFound(UUID)
    }

    func findRide(by uuid: UUID) -> AnyPublisher<Ride, Error> {
        let request: NSFetchRequest<Ride> = Ride.fetchRequest()
        request.predicate = NSPredicate(format: "%K == %@", "id"/*#keyPath(Ride.id)*/, uuid as CVarArg)
        return storage
            .fetch(request)
            .tryMap {
                guard let first = $0.first else {
                    throw StorageError.itemNotFound(uuid)
                }
                return first
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

}
