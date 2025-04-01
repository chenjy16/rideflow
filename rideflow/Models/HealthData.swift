import Foundation


// 健康数据
struct HealthData {
    var caloriesBurned: Double = 0
    var activeTime: TimeInterval = 0
    let date: Date
    var caloriesChangeRate: Double? = nil
    var activeTimeChangeRate: Double? = nil
}

// 健康见解
struct HealthInsight: Identifiable {
    let id = UUID()
    let type: HealthInsightType
    let message: String
    let changeRate: Double?
    let isPositive: Bool
}

// 健康见解类型
enum HealthInsightType {
    case caloriesBurned
    case ridingFrequency
    case activityLevel
    case consistency
}
// 用于存储时间范围内的数据点
struct TimeRangeDataPoint {
    let date: Date
    var calories: Double
    var activeTime: TimeInterval
}

// 健康指标数据点
struct HealthMetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    var value: Double  // 将 let 改为 var，使 value 可变
}
