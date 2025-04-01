import Foundation
import SwiftUI
import CoreDataStorage

class CarbonEmissionViewModel: ObservableObject {
    @Published var carbonSavedData: [HealthMetricPoint] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // 移除时间范围选择，只保留周视图
    // @Published var selectedTimeRange: TimeRange = .week
    
    private let storageService = StorageService.shared
    
    // 添加当前周的开始和结束日期
    private var currentWeekDates: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取本周的周一
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendar.date(from: components) else {
            return (today, today)
        }
        
        // 获取本周的周日
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return (startOfWeek, startOfWeek)
        }
        
        return (startOfWeek, endOfWeek)
    }
    
    init() {
        loadData()
    }
    
    func loadData() {
        isLoading = true
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 获取当前周的时间范围
            let (startDate, endDate) = self.currentWeekDates
            let rides = self.storageService.fetchRides(from: startDate, to: endDate)
            
            // 创建本周每一天的数据点
            var dataPoints = self.generateWeekDataPoints(startDate: startDate, endDate: endDate)
            
            // 按日期分组骑行数据
            let calendar = Calendar.current
            
            for ride in rides {
                guard let createdAt = ride.createdAt else { continue }
                let day = calendar.startOfDay(for: createdAt)
                
                if let summary = ride.summary {
                    let distance = summary.distance / 1000.0 // 转换为公里
                    
                    // 将数据添加到对应的日期
                    if let index = dataPoints.firstIndex(where: { calendar.isDate($0.date, equalTo: day, toGranularity: .day) }) {
                        dataPoints[index].value += CarbonEmission.calculateSavedEmission(distance: distance)
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.carbonSavedData = dataPoints
                self.isLoading = false
            }
        }
    }
    
    // 生成本周每一天的数据点
    private func generateWeekDataPoints(startDate: Date, endDate: Date) -> [HealthMetricPoint] {
        let calendar = Calendar.current
        var dataPoints: [HealthMetricPoint] = []
        var currentDate = startDate
        
        // 为本周的每一天创建数据点
        while currentDate <= endDate {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            if let groupDate = calendar.date(from: components) {
                dataPoints.append(HealthMetricPoint(date: groupDate, value: 0))
            }
            
            // 增加一天
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return dataPoints
    }
    
    // 获取上一周的数据
    private func getPreviousWeekData() -> Double {
        let calendar = Calendar.current
        let (currentStart, _) = currentWeekDates
        
        guard let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentStart),
              let previousEnd = calendar.date(byAdding: .day, value: 6, to: previousStart) else {
            return 0
        }
        
        let previousRides = storageService.fetchRides(from: previousStart, to: previousEnd)
        
        let previousDistance = previousRides.reduce(0.0) { result, ride in
            if let summary = ride.summary {
                return result + summary.distance / 1000.0
            }
            return result
        }
        
        return CarbonEmission.calculateSavedEmission(distance: previousDistance)
    }
    
    // 总碳排放节省量(克)
    var totalCarbonSaved: Double {
        // 从所有骑行记录中计算总距离
        let totalDistance = storageService.fetchAllRides().reduce(0.0) { result, ride in
            if let summary = ride.summary {
                return result + summary.distance
            }
            return result
        }
        return CarbonEmission.calculateSavedEmission(distance: totalDistance / 1000.0) // 转换为公里
    }

    // 当前周内的碳排放节省量(克)
    var periodCarbonSaved: Double {
        return carbonSavedData.reduce(0.0) { $0 + $1.value }
    }

    // 格式化的碳排放节省量
    var formattedCarbonSaved: String {
        if periodCarbonSaved < 1000 {
            return String(format: "%.0fg", periodCarbonSaved)
        } else {
            return String(format: "%.2fkg", periodCarbonSaved / 1000.0)
        }
    }

    // 环保效益描述
    var environmentalBenefitDescription: String {
        return CarbonEmission.emissionToEnvironmentalBenefit(emission: periodCarbonSaved)
    }

    // 碳排放变化率
    var carbonSavedChangeRate: Double? {
        let previousCarbonSaved = getPreviousWeekData()
        
        if previousCarbonSaved == 0 {
            return periodCarbonSaved > 0 ? 100 : 0
        }
        
        return ((periodCarbonSaved - previousCarbonSaved) / previousCarbonSaved) * 100.0
    }
    
    // 获取特定日期的骑行数据
    func fetchRides(for date: Date) -> [Ride] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return storageService.fetchRides(from: startOfDay, to: endOfDay)
    }
}
