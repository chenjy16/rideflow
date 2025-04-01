

import Combine
import Injected
import CoreDataStorage

protocol RideRepository {
    typealias RidesFuture = Future<[Ride], Error>
    func fetchRides() -> RidesFuture
}

struct CoreDataRideRepository: RideRepository {

    // 直接使用 StorageService 获取 storage
    private let storage = StorageService.getStorage()

    func fetchRides() -> RidesFuture {
        let context = storage.backgroundContext
        return RidesFuture { promise in
            context.perform {
                do {
                    let rides = try context.fetch(Ride.fetchRequest())
                    promise(.success(rides))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
