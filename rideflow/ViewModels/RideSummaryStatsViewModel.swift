import Foundation
import Combine

class RideSummaryStatsViewModel: ObservableObject {
    @Published var totalStats: TotalRideStats = TotalRideStats()
    @Published var isLoading: Bool = false
    
    private let storageService = StorageService.shared
    
    init() {
        loadTotalStats()
    }
    
    func loadTotalStats() {
        isLoading = true
        
        // 使用 DispatchQueue 替代 Task.detached
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 获取所有骑行记录
            let allRides = self.storageService.fetchAllRides()
            
            var totalDistance: Double = 0
            var totalDuration: TimeInterval = 0
            var totalElevation: Double = 0
            var weightedSpeedSum: Double = 0
            var totalRideCount: Int = 0
            
            // 计算总和 - 在同一线程处理数据
            for ride in allRides {
                // 使用安全访问方式获取 summary 数据
                guard let summary = ride.summary else {
                    continue
                }
                
                // 使用安全属性访问
                let distance = summary.safeDistance
                let duration = summary.safeDuration
                let elevation = summary.safeElevationGain
                let avgSpeed = summary.safeAvgSpeed
                
                // 添加合理的上限检查
                if distance.isFinite && distance >= 0 && distance < 1000000 { // 1000公里 = 1000000米
                    totalDistance += distance / 1000  // 修改这里：将米转换为公里
                    totalRideCount += 1
                    
                    // 只有当距离有效时才累加其他数据
                    if duration.isFinite && duration >= 0 && duration < 86400 { // 最多24小时
                        totalDuration += duration
                    }
                    
                    if elevation.isFinite && elevation >= 0 && elevation < 10000 { // 最多10000米
                        totalElevation += elevation
                    }
                    
                    if avgSpeed.isFinite && avgSpeed >= 0 && avgSpeed < 100 { // 最多100 m/s
                        weightedSpeedSum += avgSpeed * distance
                    }
                }
            }
            
            // 在主线程更新 UI
            DispatchQueue.main.async {
                let avgSpeed = totalDistance > 0 ? weightedSpeedSum / totalDistance : 0
                
                self.totalStats = TotalRideStats(
                    totalDistance: totalDistance,
                    totalDuration: totalDuration,
                    totalElevation: totalElevation,
                    averageSpeed: avgSpeed,
                    rideCount: totalRideCount  // 修改这里，使用正确的参数名 rideCount
                )
                
                self.isLoading = false
            }
        }
    }
    
    // 刷新数据的方法，可以在需要时调用
    func refreshData() {
        loadTotalStats()
    }
}

struct TotalRideStats {
    var totalDistance: Double = 0 // 现在以公里为单位存储
    var totalDuration: TimeInterval = 0
    var totalElevation: Double = 0
    var averageSpeed: Double = 0
    var rideCount: Int = 0
    
    // 格式化方法
    var formattedTotalDistance: String {
        // 已经是公里单位，直接格式化
        return String(format: "%.1f km", totalDistance)
    }
    
    var formattedTotalDuration: String {
        let hours = Int(totalDuration) / 3600
        let minutes = (Int(totalDuration) % 3600) / 60
        let seconds = Int(totalDuration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedTotalElevation: String {
        return String(format: "%.1f m", totalElevation)
    }
    
    var formattedAverageSpeed: String {
        return String(format: "%.1f km/h", averageSpeed)
    }
}
