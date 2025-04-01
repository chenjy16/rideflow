import MapKit
import Combine
import Injected
import Foundation
import CoreLocation

class RideService: Service {

    enum State {
        case idle
        case running
        case paused(Bool)
        case stopped
    }
    
    // 重命名为 RideStatus 避免与 CoreData 实体冲突
    struct RideStatus {
        var currentSpeed: Double
        var distance: Double
        var duration: TimeInterval
        var calories: Double
        var averageSpeed: Double
    }
    
    // 修改 currentRide 计算属性
    private var currentRide: RideStatus? {
        guard duration > 0 else { return nil }
        return RideStatus(
            currentSpeed: avgSpeedPublisher.value,
            distance: totalDistance / 1000, // 转换为公里
            duration: duration,
            calories: calculateCalories(),
            averageSpeed: avgSpeedPublisher.value
        )
    }
    
    private func calculateCalories() -> Double {
        // 简单估算，实际应用中可能需要更复杂的计算
        return duration * avgSpeedPublisher.value * 0.1
    }
    


    @Injected private var locationService: LocationService
    @Injected private var storageService: StorageService

    let shouldAutostart = false

    private var locations = [CLLocation]()
    private var totalDistance: CLLocationDistance = 0
    private var duration: TimeInterval = 0
    private var elevationGain: CLLocationDistance = 0
    private var elevationGainProcessor: ElevationGainProcessor?

    private let trackPublisher = PassthroughSubject<MKPolyline, Never>()
    private(set) var track: AnyPublisher<MKPolyline, Never>

    private let distancePublisher = CurrentValueSubject<CLLocationDistance, Never>(0)
    private(set) var distance: AnyPublisher<CLLocationDistance, Never>

    private let avgSpeedPublisher = CurrentValueSubject<CLLocationSpeed, Never>(0)
    private(set) var avgSpeed: AnyPublisher<CLLocationSpeed, Never>

    private var startDate: TimeInterval = 0
    private var pausedDate: TimeInterval = 0
    private var stopDate: TimeInterval = 0
    private var timer = Timer2()
    private var timerCancellable: AnyCancellable?

    private let elapsedTimePublisher = CurrentValueSubject<TimeInterval, Never>(0)
    private(set) var elapsed: AnyPublisher<TimeInterval, Never>

    private let statePublisher = CurrentValueSubject<State, Never>(.idle)
    private(set) var state: AnyPublisher<State, Never>

    private var cancellable = Set<AnyCancellable>()
    private var location: AnyCancellable?
    
    // 语音播报相关属性
    private var voiceEventManager: VoiceEventManager
    private var lastDistanceMilestone: Int = 0
    
    // 上次播报的秒数属性
    private var lastAnnouncementSeconds = 0
    
    init() {
        // 初始化存储属性
        self.elapsed = elapsedTimePublisher.eraseToAnyPublisher()
        self.state = statePublisher.eraseToAnyPublisher()
        self.track = trackPublisher.eraseToAnyPublisher()
        self.distance = distancePublisher.eraseToAnyPublisher()
        self.avgSpeed = avgSpeedPublisher.eraseToAnyPublisher()
        self.voiceEventManager = VoiceEventManager.shared
       
        // 重置状态
        reset()
       
        // 设置状态订阅
        self.state
            .receive(on: DispatchQueue.main) // 添加这一行，确保在主线程处理
            .sink { state in
                switch state {
                case .running:
                    UIApplication.shared.isIdleTimerDisabled = true
                case .idle, .paused, .stopped:
                    UIApplication.shared.isIdleTimerDisabled = false
                }
            }.store(in: &cancellable)
        
        // 添加应用前台切换通知监听
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppForeground),
            name: Notification.Name("VoiceServiceDidEnterForeground"),
            object: nil
        )
       
        // 设置骑行状态变化通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(workoutStateChanged),
            name: .workoutStateChanged,
            object: nil
        )
    }
    
    @objc private func workoutStateChanged(_ notification: Notification) {
        if let isActive = notification.object as? Bool {
            if isActive {
                // 骑行开始，设置定时播报
                setupPeriodicAnnouncements()
            } else {
                // 骑行结束，停止定时播报
                stopPeriodicAnnouncements()
                
                // 播报骑行总结
                if let ride = currentRide {
                    // 使用本地化管理器获取本地化字符串
                    let localizationManager = VoiceLocalizationManager.shared
                    let localizedMessage = localizationManager.localizedString(for: "workout_completed")
                    
                    let event = VoiceEvent(
                        type: .workout,
                        message: localizedMessage,  // 使用本地化的消息
                        priority: .high,
                        data: [
                            "speed": ride.averageSpeed,
                            "distance": ride.distance,
                            "duration": ride.duration,
                            "calories": ride.calories
                        ]
                    )
                    voiceEventManager.announceEvent(event)
                }
            }
        }
    }

    // 设置定期播报
    private func setupPeriodicAnnouncements() {
        // 重置里程碑和上次播报时间
        lastDistanceMilestone = 0
        lastAnnouncementSeconds = 0
        
        // 立即进行一次播报（延迟3秒，让用户准备好）
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.announceCurrentStatus()
        }
    }

    // 在deinit中确保清理资源
    deinit {
        stopPeriodicAnnouncements()
        // 确保移除所有通知观察者
        NotificationCenter.default.removeObserver(self)
        // 取消所有订阅
        timerCancellable?.cancel()
        location?.cancel()
        cancellable.forEach { $0.cancel() }
        cancellable.removeAll()
    }

    // 停止定期播报
    private func stopPeriodicAnnouncements() {
        // 只需重置状态
        lastAnnouncementSeconds = 0
    }

    // 播报当前状态
    private func announceCurrentStatus() {
        guard let ride = currentRide else { return }
        
        // 创建语音事件
        let event = VoiceEvent(
            type: .speed,
            message: "",  // 消息将由 VoiceEventManager 根据类型和数据生成
            priority: .normal,
            data: [
                "speed": ride.currentSpeed,
                "distance": ride.distance,
                "duration": ride.duration,
                "calories": ride.calories
            ]
        )
        
        voiceEventManager.announceEvent(event)
        
  
    }

   
    
    // 重置骑行数据
    func reset() {
        startDate = 0
        pausedDate = 0
        stopDate = 0
        totalDistance = 0
        elevationGain = 0
    }

    // 开始骑行
    func start() {
        startDate = Date.timeIntervalSinceReferenceDate
        statePublisher.send(.running)
        
        // 发送骑行状态变化通知
        NotificationCenter.default.post(name: .workoutStateChanged, object: true)

        locationStart()
        run()
    }

    // 重新开始骑行
    func restart() {
        reset()
        start()
    }

    // 暂停骑行
    func pause(automatic: Bool = false) {
        locationService.stop()
        pausedDate = Date.timeIntervalSinceReferenceDate
        lastAnnouncementSeconds = Int(duration)
        timerCancellable?.cancel()
        statePublisher.send(.paused(automatic))
    }

    // 恢复骑行
    func resume() {
        startDate += (Date.timeIntervalSinceReferenceDate - pausedDate)
        statePublisher.send(.running)

        locationStart()
        run()
    }

    // 停止骑行
    func stop() {
        locationService.stop()
        stopDate = Date.timeIntervalSinceReferenceDate
        statePublisher.send(.stopped)
        timerCancellable?.cancel()
        elapsedTimePublisher.send(0)
        distancePublisher.send(0)
        elevationGainProcessor = nil
        
        // 发送骑行状态变化通知
        NotificationCenter.default.post(name: .workoutStateChanged, object: false)
        
        storeRide()
        locations.removeAll()
    }

    // 切换骑行状态
    func toggle() {
        switch statePublisher.value {
        case .idle:
            start()
        case .paused:
            resume()
        case .running:
            pause()
        case .stopped:
            restart()
        }
    }

    private func run() {
        timerCancellable?.cancel()
        
        // 重置上次播报时间
        lastAnnouncementSeconds = 0
        
        // 修改这里，直接使用 timer 而不是 timer.publisher
        timerCancellable = timer.timer
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                // 更新持续时间
                self.duration = self.calculateDuration()
                self.elapsedTimePublisher.send(self.duration)
                
                // 只在骑行状态为运行时处理播报
                if case .running = self.statePublisher.value {
                    self.checkTimePointAnnouncement()
                }
            }
    }
    
    // 计算持续时间
    private func calculateDuration() -> TimeInterval {
        guard startDate > 0 else { return 0 }
        return Date.timeIntervalSinceReferenceDate - startDate
    }
    

    // 改进定时播报检测逻辑
    private func checkTimePointAnnouncement() {
        let currentSeconds = Int(self.duration)
        let defaults = UserDefaults.standard
        
        // 如果刚从后台返回，跳过此次检查
        if justReturnedFromBackground {
            // 记录上次播报时间，避免重复播报
            lastAnnouncementSeconds = currentSeconds
            justReturnedFromBackground = false
            return
        }
        
        // 使用更精确的时间检测机制
        let timeSinceLastAnnouncement = currentSeconds - lastAnnouncementSeconds
        
        // 检查是否需要播报
        var shouldAnnounce = false
        var announcementInterval = 0
        
        // 优先检查较长的时间间隔，并确保不会重复播报
        if defaults.bool(forKey: "announce_every_10_minutes") &&
           currentSeconds >= 600 && // 至少10分钟
           currentSeconds % 600 == 0 && // 整10分钟
           timeSinceLastAnnouncement >= 540 { // 距离上次播报至少9分钟
            shouldAnnounce = true
            announcementInterval = 600
        } else if defaults.bool(forKey: "announce_every_5_minutes") &&
                  currentSeconds >= 300 && // 至少5分钟
                  currentSeconds % 300 == 0 && // 整5分钟
                  timeSinceLastAnnouncement >= 240 { // 距离上次播报至少4分钟
            shouldAnnounce = true
            announcementInterval = 300
        } else if defaults.bool(forKey: "announce_every_minute") &&
                  currentSeconds >= 60 && // 至少1分钟
                  currentSeconds % 60 == 0 && // 整1分钟
                  timeSinceLastAnnouncement >= 50 { // 距离上次播报至少50秒
            shouldAnnounce = true
            announcementInterval = 60
        }
        
        if shouldAnnounce {
            // 更新上次播报时间
            lastAnnouncementSeconds = currentSeconds
            
            // 播报当前状态
            announceCurrentStatus()
        }
    }
    
    // 添加一个标记属性
    private var justReturnedFromBackground = false
    
    @objc private func handleAppForeground(_ notification: Notification) {
        // 避免在主线程中执行耗时操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let timeInBackground = notification.object as? TimeInterval {
                // 应用回到前台后，更新上次播报时间，避免立即播报
                self.lastAnnouncementSeconds = Int(self.duration)
                self.justReturnedFromBackground = true
                
                // 如果骑行正在进行，可以播报一次当前状态
                if case .running = self.statePublisher.value {
                    // 使用弱引用避免循环引用
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                        guard let self = self else { return }
                        self.announceCurrentStatus()
                        self.justReturnedFromBackground = false
                    }
                } else {
                    // 确保在非运行状态下也重置标志
                    self.justReturnedFromBackground = false
                }
            }
        }
    }

    // 启动位置服务
    private func locationStart() {
        location?.cancel()
        locationService.start()
        location = locationService.location
            .sink { [weak self] location in self?.handle(location: location) }
    }

    // 存储骑行数据
        private func storeRide() {
            let date = Date()
            storageService.createNewRide(
                name: generateRideName(date: date),
                summary: Summary(
                    duration: duration,
                    distance: totalDistance,
                    avgSpeed: locations.average(by: \.speed),
                    maxSpeed: locations.max(by: \.speed)?.speed ?? .zero,
                    elevationGain: elevationGain
                ),
                locations: locations,
                createdAt: date
            )
        }
    
       // 生成骑行名称
        private func generateRideName(date: Date) -> String {
            let weekDay = Formatters.rideTitleDateFormatter.string(from: date)
            return "\(weekDay) Ride"
        }
        
        // 处理位置更新
        private func handle(location: CLLocation) {
            // 初始化处理器（如果需要）
            if elevationGainProcessor == nil {
                if let altitude = locations.last?.altitude {
                    elevationGainProcessor = ElevationGainProcessor(initialAltitude: altitude)
                } else {
                    elevationGainProcessor = ElevationGainProcessor(initialAltitude: location.altitude)
                }
            }
            
            // 使用处理器计算海拔增益
            if let processor = elevationGainProcessor {
                self.elevationGain = processor.process(input: location.altitude)
            }

            self.locations.append(location)

            guard self.locations.count >= 2 else {
                return
            }

            // 计算轨迹线
            let locationA = self.locations[self.locations.count - 2]
            let locationB = self.locations[self.locations.count - 1]
            var coordinates = [locationA, locationB].map { $0.coordinate }
            self.trackPublisher.send(MKPolyline(coordinates: &coordinates, count: 2))
            let delta = locationA.distance(from: locationB)
            self.totalDistance += delta
            self.distancePublisher.send(self.totalDistance)

            let avgSpeed = self.totalDistance / self.duration
            self.avgSpeedPublisher.send(avgSpeed)
        }
    
    

}
