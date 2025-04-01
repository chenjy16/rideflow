import Foundation
import Combine

enum VoiceEventType {
    case speed
    case distance
    case time
    case calories
    case workout
    case error
}

struct VoiceEvent {
    let type: VoiceEventType
    let message: String
    let priority: SpeechPriority
    let data: [String: Any]?
    
    init(type: VoiceEventType, message: String, priority: SpeechPriority = .normal, data: [String: Any]? = nil) {
        self.type = type
        self.message = message
        self.priority = priority
        self.data = data
    }
}

extension Notification.Name {
    static let workoutStateChanged = Notification.Name("workoutStateChanged")
}

class VoiceEventManager {
    static let shared = VoiceEventManager()
    
    private var voiceService: VoiceService
    private var cancellables = Set<AnyCancellable>()
    private var lastAnnouncementTime: [VoiceEventType: Date] = [:]
    private var workoutActive = false
    
    private init() {
        self.voiceService = VoiceService.shared
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // 监听运动状态变化
        NotificationCenter.default.publisher(for: .workoutStateChanged)
            .sink { [weak self] notification in
                if let isActive = notification.object as? Bool {
                    self?.workoutActive = isActive
                }
            }
            .store(in: &cancellables)
    }
    
    
    private func shouldAnnounce(_ eventType: VoiceEventType) -> Bool {
        // 高优先级事件总是播报
        if eventType == .error  || eventType == .workout {
            return true
        }
        
        // 检查用户设置是否允许播报此类型
        if !isEventTypeEnabled(eventType) {
            return false
        }
        
        // 检查是否超过最小播报间隔
        if let lastTime = lastAnnouncementTime[eventType] {
            let minInterval = getMinimumInterval(for: eventType)
            let timeSinceLastAnnouncement = Date().timeIntervalSince(lastTime)
            
            if timeSinceLastAnnouncement < minInterval {
                return false
            }
        }
        
        return true
    }
    
    
    // 添加获取最小播报间隔的方法
    private func getMinimumInterval(for eventType: VoiceEventType) -> TimeInterval {
        switch eventType {
        case .speed:
            return 5.0  // 速度至少间隔5秒
        case .distance:
            return 10.0  // 距离至少间隔10秒
        case .time:
            return 10.0  // 时间至少间隔10秒
        case .calories:
            return 30.0  // 卡路里至少间隔30秒
        case .workout:
            return 0.0  // 骑行状态无间隔限制
        case .error:
            return 0.0  // 错误无间隔限制
        }
    }

    
    private func isEventTypeEnabled(_ eventType: VoiceEventType) -> Bool {
        switch eventType {
        case .speed:
            return UserDefaults.standard.bool(forKey: "announce_speed")
        case .distance:
            return UserDefaults.standard.bool(forKey: "announce_distance")
        case .time:
            return UserDefaults.standard.bool(forKey: "announce_time")
        case .calories:
            return UserDefaults.standard.bool(forKey: "announce_calories")
        case .workout, .error:
            return true // 这些类型总是启用
        }
    }
    
    
    // 处理带有数据的事件
    private func processEventWithData(_ event: VoiceEvent) {
        guard let data = event.data else {
            voiceService.speak(event.message, priority: event.priority)
            return
        }
        
        switch event.type {
        case .speed:
            // 使用安全的类型转换
            let speed = data["speed"] as? Double ?? 0.0
            let distance = data["distance"] as? Double ?? 0.0
            let duration = data["duration"] as? TimeInterval ?? 0.0
            let calories = data["calories"] as? Double ?? 0.0
            
            // 使用 VoiceService 的综合播报方法
            voiceService.announceCurrentStatus(
                speed: speed,
                distance: distance,
                duration: duration,
                calories: calories
            )
            
            
        default:
            // 其他类型的事件直接使用原始消息
            voiceService.speak(event.message, priority: event.priority)
        }
    }

        
    
    // 修改 announceEvent 方法
    func announceEvent(_ event: VoiceEvent) {
        // 检查是否应该播报
        if shouldAnnounce(event.type) {
            // 更新最后播报时间
            lastAnnouncementTime[event.type] = Date()
            
            // 处理事件
            if event.data != nil {
                processEventWithData(event)
            } else {
                voiceService.speak(event.message, priority: event.priority)
            }
        }
    }
}


