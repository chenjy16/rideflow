import Foundation
import SwiftUI
import CoreDataStorage

class RideHealthViewModel: ObservableObject {
    @Published var healthData: HealthData?
    @Published var caloriesData: [HealthMetricPoint] = []
    @Published var activeTimeData: [HealthMetricPoint] = []
    @Published var healthInsights: [HealthInsight] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let storageService = StorageService.shared
    
    
    // Add user weight range selection
    @Published var selectedWeightRange: WeightRange = .medium {
        didSet {
            // When weight range changes, reload data
            if oldValue != selectedWeightRange {
                // Save user's selected weight range
                UserDefaults.standard.set(selectedWeightRange.rawValue, forKey: "userWeightRange")
                loadData()
            }
        }
    }
    
    // Add current week's start and end dates
    private var currentWeekDates: (start: Date, end: Date) {
        let calendar = Calendar.current
        let today = Date()
        
        // Get Monday of this week
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let startOfWeek = calendar.date(from: components) else {
            return (today, today)
        }
        
        // Get Sunday of this week
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            return (startOfWeek, startOfWeek)
        }
        
        return (startOfWeek, endOfWeek)
    }
    
    private func getUserWeight() -> Double {
        // Return middle value based on selected weight range
        return selectedWeightRange.middleValue
    }
    
    // Formatted calories burned
    var formattedCaloriesBurned: String {
        guard let healthData = healthData else { return "0 kcal" }
        return String(format: "%.0f kcal", healthData.caloriesBurned)
    }
    
    // Calories change rate
    var caloriesChangeRate: Double? {
        return healthData?.caloriesChangeRate
    }
    
    // Formatted active time
    var formattedActiveTime: String {
        guard let healthData = healthData else { return "0h 0m" }
        let hours = Int(healthData.activeTime / 3600)
        let minutes = Int((healthData.activeTime.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    // Active time change rate
    var activeTimeChangeRate: Double? {
        return healthData?.activeTimeChangeRate
    }
    
    // Modify load health data method, use only week view
    func loadData() {
        isLoading = true
        errorMessage = nil
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            let (startDate, endDate) = self.currentWeekDates
            
            // Get rides within this time range
            let rides = self.storageService.fetchRidesInDateRange(from: startDate, to: endDate)
            
            if rides.isEmpty {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.caloriesData = []
                    self.activeTimeData = []
                    self.healthData = HealthData(date: Date())
                    self.generateHealthInsights(rides: [], previousRides: [])
                }
                return
            }
            
            // Calculate calories burned and active time
            var totalCalories: Double = 0
            var totalActiveTime: TimeInterval = 0
            
            // Create data points for each day of the week
            var dataPoints = self.generateWeekDataPoints(startDate: startDate, endDate: endDate)
            
            // Process ride data
            for ride in rides {
                guard let date = ride.createdAt, let summary = ride.summary else { continue }
                
                // Calculate calories burned
                let avgSpeedMps = summary.avgSpeed // Average speed (meters/second)
                let duration = summary.duration // Duration (seconds)
                let weight = self.getUserWeight() // Use user's selected weight
                
                // Estimate power and calories burned
                let power = EnergyUtil.estimatePower(weight: weight, speed: avgSpeedMps)
                let calories = EnergyUtil.calories(power: power, duration: duration)
                
                // Add data to corresponding date
                let calendar = Calendar.current
                let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
                if let groupDate = calendar.date(from: dateComponents) {
                    if let index = dataPoints.firstIndex(where: { calendar.isDate($0.date, equalTo: groupDate, toGranularity: .day) }) {
                        dataPoints[index].calories += calories
                        dataPoints[index].activeTime += duration
                    }
                }
                
                totalCalories += calories
                totalActiveTime += duration
            }
            
            // Get rides from previous week for calculating change rate
            let calendar = Calendar.current
            guard let previousStartDate = calendar.date(byAdding: .weekOfYear, value: -1, to: startDate),
                  let previousEndDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate) else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Date calculation error"
                }
                return
            }
            
            let previousRides = self.storageService.fetchRidesInDateRange(from: previousStartDate, to: previousEndDate)
            
            // Calculate calories burned and active time for previous week
            var previousTotalCalories: Double = 0
            var previousTotalActiveTime: TimeInterval = 0
            
            for ride in previousRides {
                guard let summary = ride.summary else { continue }
                
                let avgSpeedMps = summary.avgSpeed
                let duration = summary.duration
                let weight = self.getUserWeight() // Use user's selected weight
                
                let power = EnergyUtil.estimatePower(weight: weight, speed: avgSpeedMps)
                let calories = EnergyUtil.calories(power: power, duration: duration)
                
                previousTotalCalories += calories
                previousTotalActiveTime += duration
            }
            
            // Calculate change rates
            let caloriesChangeRate = previousTotalCalories > 0 ?
                (totalCalories - previousTotalCalories) / previousTotalCalories * 100 : nil
            
            let activeTimeChangeRate = previousTotalActiveTime > 0 ?
                (totalActiveTime - previousTotalActiveTime) / previousTotalActiveTime * 100 : nil
            
            // Create health data object
            let healthData = HealthData(
                caloriesBurned: totalCalories,
                activeTime: totalActiveTime,
                date: Date(),
                caloriesChangeRate: caloriesChangeRate,
                activeTimeChangeRate: activeTimeChangeRate
            )
            
            // Convert data points to chart data
            let caloriesPoints = dataPoints.map { HealthMetricPoint(date: $0.date, value: $0.calories) }
            let activeTimePoints = dataPoints.map { HealthMetricPoint(date: $0.date, value: $0.activeTime / 60) } // Convert to minutes
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.healthData = healthData
                self.caloriesData = caloriesPoints
                self.activeTimeData = activeTimePoints
                self.generateHealthInsights(rides: rides, previousRides: previousRides)
            }
        }
    }
    
    // Generate data points for each day of the week
    private func generateWeekDataPoints(startDate: Date, endDate: Date) -> [TimeRangeDataPoint] {
        let calendar = Calendar.current
        var dataPoints: [TimeRangeDataPoint] = []
        var currentDate = startDate
        
        // Create data points for each day of the week
        while currentDate <= endDate {
            let components = calendar.dateComponents([.year, .month, .day], from: currentDate)
            if let groupDate = calendar.date(from: components) {
                dataPoints.append(TimeRangeDataPoint(date: groupDate, calories: 0, activeTime: 0))
            }
            
            // Add one day
            if let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) {
                currentDate = nextDate
            } else {
                break
            }
        }
        
        return dataPoints
    }
    
    private func generateHealthInsights(rides: [Ride], previousRides: [Ride]) {
        var insights: [HealthInsight] = []
        
        // Calories burned insight
        if let caloriesChangeRate = healthData?.caloriesChangeRate, let calories = healthData?.caloriesBurned {
            let isPositive = caloriesChangeRate >= 0
            let message: String
            
            if isPositive {
                message = String(format: "This week you've burned %.0f calories, which is %.0f%% more than last week",
                                calories, abs(caloriesChangeRate))
            } else {
                message = String(format: "This week you've burned %.0f calories, which is %.0f%% less than last week",
                                calories, abs(caloriesChangeRate))
            }
            
            insights.append(HealthInsight(
                type: .caloriesBurned,
                message: message,
                changeRate: caloriesChangeRate,
                isPositive: isPositive
            ))
        }
        
        // Riding frequency insight
        let currentRideCount = rides.count
        let previousRideCount = previousRides.count
        
        if currentRideCount > 0 || previousRideCount > 0 {
            let rideCountChange = previousRideCount > 0 ?
                Double(currentRideCount - previousRideCount) / Double(previousRideCount) * 100 : nil
            
            let isPositive = (rideCountChange ?? 0) >= 0
            var message: String
            
            if currentRideCount < 3 {
                message = "Consider increasing your weekly rides to improve your basal metabolic rate"
            } else if let change = rideCountChange {
                if isPositive && change > 0 {
                    message = String(format: "Your riding frequency has increased by %.0f%% compared to last week. Keep it up!",
                                    abs(change))
                } else if !isPositive {
                    message = String(format: "Your riding frequency has decreased by %.0f%% compared to last week. Consider riding more often",
                                    abs(change))
                } else {
                    message = String(format: "Your riding frequency is consistent with last week, showing stable performance")
                }
            } else {
                message = "This is your first week of recording ride data. Keep it up!"
            }
            
            insights.append(HealthInsight(
                type: .ridingFrequency,
                message: message,
                changeRate: rideCountChange,
                isPositive: isPositive || rideCountChange == nil
            ))
        }
        
        // Activity level insight
        if let activeTimeChangeRate = healthData?.activeTimeChangeRate {
            let isPositive = activeTimeChangeRate >= 0
            let message: String
            
            if isPositive {
                message = String(format: "Your activity level has increased by %.0f%% compared to last week",
                                abs(activeTimeChangeRate))
            } else {
                message = String(format: "Your activity level has decreased by %.0f%% compared to last week. Consider increasing your activity time",
                                abs(activeTimeChangeRate))
            }
            
            insights.append(HealthInsight(
                type: .activityLevel,
                message: message,
                changeRate: activeTimeChangeRate,
                isPositive: isPositive
            ))
        }
        
        // Consistency insight
        if currentRideCount >= 3 {
            insights.append(HealthInsight(
                type: .consistency,
                message: "Maintaining regular riding habits helps improve cardiovascular function and basal metabolic rate",
                changeRate: nil,
                isPositive: true
            ))
        }
        
        DispatchQueue.main.async {
            self.healthInsights = insights
        }
    }
    
    init() {
        // Load user's previously selected weight range from UserDefaults
        if let savedWeightRange = UserDefaults.standard.string(forKey: "userWeightRange"),
           let weightRange = WeightRange(rawValue: savedWeightRange) {
            selectedWeightRange = weightRange
        }
        
        loadData()
    }
}
