import Foundation
import Combine

class RideTrendsViewModel: ObservableObject {
    @Published var dailySummaries: [DailyRideSummary] = []
    @Published var isLoading = false
    
    private let storageService = StorageService.shared
    
    func loadData() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let calendar = Calendar.current
            let today = Date()
            
            // 获取本周的周一日期
            var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
            guard let startDate = calendar.date(from: components) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.dailySummaries = []
                }
                return
            }
            
            // 获取本周的周日日期
            guard let endDate = calendar.date(byAdding: .day, value: 6, to: startDate) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.dailySummaries = []
                }
                return
            }
            
            // 获取日期范围内的骑行记录
            let rides = self.storageService.fetchRidesInDateRange(from: startDate, to: endDate)
            

            var summaries: [DailyRideSummary] = []
            
            for dayOffset in 0...6 {
                guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
                
                // 获取当天的骑行记录
                let dayRides = rides.filter { ride in
                    guard let rideDate = ride.createdAt else { return false }
                    return calendar.isDate(rideDate, inSameDayAs: date)
                }
                
                if dayRides.isEmpty {
                    // 如果当天没有骑行记录，添加一个空记录
                    summaries.append(DailyRideSummary(date: date, distance: 0, avgSpeed: 0, duration: 0, elevationGain: 0))
                } else {
                    // 如果有骑行记录，计算汇总数据
                    let totalDistance = dayRides.reduce(0) { $0 + ($1.summary?.distance ?? 0) } / 1000 // 转换为公里
                    let avgSpeed = dayRides.reduce(0) { $0 + ($1.summary?.avgSpeed ?? 0) } / Double(dayRides.count)
                    let totalDuration = dayRides.reduce(0) { $0 + ($1.summary?.duration ?? 0) }
                    let totalElevation = dayRides.reduce(0) { $0 + ($1.summary?.elevationGain ?? 0) }
                    
           
                    
                    summaries.append(DailyRideSummary(
                        date: date,
                        distance: totalDistance,
                        avgSpeed: avgSpeed,
                        duration: totalDuration,
                        elevationGain: totalElevation
                    ))
                }
            }
            
            DispatchQueue.main.async {
                self.dailySummaries = summaries
                self.isLoading = false
            }
        }
    }
    
    // 将 Ride 实体转换为 DailyRideSummary
    private func convertRideToSummary(_ ride: Ride) -> DailyRideSummary {
        let date = ride.createdAt ?? Date()
        
        // 获取日期的开始时间（去除时分秒）
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        let groupDate = calendar.date(from: components) ?? date
        
        // 安全获取 summary 数据
        guard let summary = ride.summary else {
            // 如果没有 summary，返回空数据
            return DailyRideSummary(
                date: groupDate,
                distance: 0,
                avgSpeed: 0,
                duration: 0,
                elevationGain: 0
            )
        }
        
        // 使用安全属性访问方式
        return DailyRideSummary(
            date: groupDate,
            distance: summary.safeDistance / 1000, // 转换为公里
            avgSpeed: summary.safeAvgSpeed * 3.6,  // 转换为公里/小时
            duration: summary.safeDuration,        // 秒
            elevationGain: summary.safeElevationGain // 米
        )
    }
}


