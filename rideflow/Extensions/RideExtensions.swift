import Foundation
import CoreLocation
import CoreDataStorage

extension Ride {
    // 使用新名称，避免与现有方法冲突
    func asTrendSummary() -> RideTrendSummary {
        let summary = self.summary
        
        return RideTrendSummary(
            distance: summary?.distance ?? 0,
            avgSpeed: summary?.avgSpeed ?? 0,
            maxSpeed: summary?.maxSpeed ?? 0,
            duration: summary?.duration ?? 0,
            elevationGain: summary?.elevationGain ?? 0
        )
    }
    
    // 添加 asDailyRideSummary 方法，用于 RideTrendsViewModel
    func asDailyRideSummary() -> DailyRideSummary {
        let date = createdAt ?? Date()
        let summary = self.summary
        
        return DailyRideSummary(
            date: date,
            distance: summary?.distance ?? 0,
            avgSpeed: summary?.avgSpeed ?? 0,
            duration: summary?.duration ?? 0,
            elevationGain: summary?.elevationGain ?? 0
        )
    }
}
