import Foundation
import SwiftUI
import CoreDataStorage

class RideComparisonViewModel: ObservableObject {
    @Published var selectedRides: [Ride] = []
    @Published var availableRides: [Ride] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    private let storageService = StorageService.shared
    
    init() {
        loadAvailableRides()
    }
    
    func loadAvailableRides() {
        isLoading = true
        
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 获取所有骑行记录
            let allRides = self.storageService.fetchAllRides()
            
            DispatchQueue.main.async {
                // 按照时间排序，最新的在前面
                self.availableRides = allRides.sorted(by: {
                    ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast)
                })
                self.isLoading = false
            }
        }
    }
    
    func toggleRideSelection(_ ride: Ride) {
        if selectedRides.contains(where: { $0.id == ride.id }) {
            selectedRides.removeAll { $0.id == ride.id }
        } else {
            // 限制最多选择10次骑行
            if selectedRides.count < 10 {
                selectedRides.append(ride)
            }
        }
    }
    
    func isSelected(_ ride: Ride) -> Bool {
        return selectedRides.contains(where: { $0.id == ride.id })
    }
    
    // 获取选中骑行的各项指标，用于图表和表格显示
    func getComparisonData() -> [String: [RideDataPoint]] {
        var data: [String: [RideDataPoint]] = [
            "distance": [],
            "avgSpeed": [],
            "elevation": [],
            "duration": []
        ]
        
        // 按照时间排序，最早的在前面
        let sortedRides = selectedRides.sorted(by: {
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        })
        
        for ride in sortedRides {
            if let summary = ride.summary, let date = ride.createdAt {
                // 将距离从米转换为公里
                data["distance"]?.append(RideDataPoint(date: date, value: summary.distance / 1000, rideName: ride.name ?? "未命名"))
                data["avgSpeed"]?.append(RideDataPoint(date: date, value: summary.avgSpeed, rideName: ride.name ?? "未命名"))
                data["elevation"]?.append(RideDataPoint(date: date, value: summary.elevationGain, rideName: ride.name ?? "未命名"))
                data["duration"]?.append(RideDataPoint(date: date, value: summary.duration / 60, rideName: ride.name ?? "未命名")) // 转换为分钟
            }
        }
        
        return data
    }
}

// 用于图表显示的数据点结构
struct RideDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
    let rideName: String
    
    // 格式化的日期，用于显示
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd\nHH:mm:ss"
        return formatter.string(from: date)
    }
    
    // 简短格式的日期，用于表格显示
    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd HH:mm"
        return formatter.string(from: date)
    }
}
