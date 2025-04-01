import Foundation
import CoreDataStorage
import CoreData

extension StorageService {
    
    
    /// 通用方法：获取所有符合条件的托管对象
    /// - Parameter request: 查询请求
    /// - Returns: 查询结果数组
    private func fetchAll<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        var results: [T] = []
        
        // 使用 performAndWait 确保在正确的线程上下文中执行
        storage.mainContext.performAndWait {
            do {
                results = try storage.mainContext.fetch(request)
            } catch {
                print("获取数据错误: \(error)")
            }
        }
        
        return results
    }
    
    /// 获取指定日期范围内的骑行记录
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 骑行记录数组
    func fetchRides(from startDate: Date, to endDate: Date) -> [Ride] {
        // 添加错误处理，确保日期范围有效
        guard startDate <= endDate else {
            print("Error: startDate is later than endDate")
            return []
        }
        
        let fetchRequest = Ride.fetchRequest()
        
        // 按日期范围筛选
        fetchRequest.predicate = NSPredicate(
            format: "createdAt >= %@ AND createdAt <= %@",
            startDate as NSDate,
            endDate as NSDate
        )
        
        // 按日期排序
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        return fetchAll(fetchRequest)
    }
    
    func fetchAllRides() -> [Ride] {
        let request: NSFetchRequest<Ride> = Ride.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        // 使用 performAndWait 确保在正确的线程上下文中执行
        var results: [Ride] = []
        storage.mainContext.performAndWait {
            do {
                results = try storage.mainContext.fetch(request)
            } catch {
                print("获取骑行数据错误: \(error)")
            }
        }
        
        return results
    }
    
    func fetchRidesInDateRange(from startDate: Date, to endDate: Date) -> [Ride] {
        let request: NSFetchRequest<Ride> = Ride.fetchRequest()
        request.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        // 使用 performAndWait 确保在正确的线程上下文中执行
        var results: [Ride] = []
        storage.mainContext.performAndWait {
            do {
                results = try storage.mainContext.fetch(request)
            } catch {
                print("获取骑行数据错误: \(error)")
            }
        }
        
        return results
    }
    
    /// 根据ID获取骑行记录
    /// - Parameter id: 骑行记录ID
    /// - Returns: 骑行记录（如果存在）
    func fetchRide(byId id: UUID) -> Ride? {
        let request = Ride.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        return fetchAll(request).first
    }
    

    
    /// 保存骑行记录
    /// - Parameter ride: 要保存的骑行记录
    func saveRide(_ ride: Ride) {
        storage.mainContext.performAndWait {
            do {
                try storage.mainContext.save()
                print("骑行记录保存成功")
            } catch {
                print("保存骑行记录失败: \(error)")
            }
        }
    }
    
    /// 删除骑行记录
    /// - Parameter ride: 要删除的骑行记录
    func deleteRide(_ ride: Ride) {
        storage.mainContext.performAndWait {
            storage.mainContext.delete(ride)
            
            do {
                try storage.mainContext.save()
                print("骑行记录删除成功")
            } catch {
                print("删除骑行记录失败: \(error)")
            }
        }
    }

}
