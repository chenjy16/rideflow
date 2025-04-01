import Foundation
import Combine

class WorkoutStateMonitor {
    static let shared = WorkoutStateMonitor()
    
    private var cancellables = Set<AnyCancellable>()
    @Published var isWorkoutActive = false
    
    private init() {
        setupNotifications()
    }
    
    private func setupNotifications() {
        // 监听运动开始通知
        NotificationCenter.default.publisher(for: .workoutStarted)
            .sink { [weak self] _ in
                self?.isWorkoutActive = true
                NotificationCenter.default.post(name: .workoutStateChanged, object: true)
            }
            .store(in: &cancellables)
        
        // 监听运动暂停通知
        NotificationCenter.default.publisher(for: .workoutPaused)
            .sink { [weak self] _ in
                self?.isWorkoutActive = false
                NotificationCenter.default.post(name: .workoutStateChanged, object: false)
            }
            .store(in: &cancellables)
        
        // 监听运动恢复通知
        NotificationCenter.default.publisher(for: .workoutResumed)
            .sink { [weak self] _ in
                self?.isWorkoutActive = true
                NotificationCenter.default.post(name: .workoutStateChanged, object: true)
            }
            .store(in: &cancellables)
        
        // 监听运动结束通知
        NotificationCenter.default.publisher(for: .workoutEnded)
            .sink { [weak self] _ in
                self?.isWorkoutActive = false
                NotificationCenter.default.post(name: .workoutStateChanged, object: false)
            }
            .store(in: &cancellables)
    }
}

// 扩展通知名称
extension Notification.Name {
    static let workoutStarted = Notification.Name("workoutStarted")
    static let workoutPaused = Notification.Name("workoutPaused")
    static let workoutResumed = Notification.Name("workoutResumed")
    static let workoutEnded = Notification.Name("workoutEnded")
  
}
