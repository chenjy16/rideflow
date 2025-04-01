import Foundation
import AVFoundation
import Combine
import UIKit

enum SpeechPriority {
    case low
    case normal
    case high
}

class VoiceService: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = VoiceService()
    
    private let speechSynthesizer = AVSpeechSynthesizer()
    private var speechQueue: [AVSpeechUtterance] = []
    private var isProcessingQueue = false
    
    var isVoiceEnabled = true
    var voiceRate: Float = 0.5
    var voiceLanguage: String = "en-US"  // 默认使用英语
    var voiceVolume: Float = 1.0
    
    private var backgroundDate: Date?
    
    // 改进初始化方法
    private override init() {
        super.init()
        speechSynthesizer.delegate = self
        
        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers, .mixWithOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("设置音频会话失败: \(error)")
        }
        
        loadSettings()
        
        // 添加应用状态监听
        setupNotifications()
        
        // 验证语音可用性
        verifyVoiceAvailability()
    }
    
    
    // 添加通知设置方法
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioSessionInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
    }

    // 添加音频会话中断处理
    @objc private func handleAudioSessionInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // 音频会话被中断（例如来电）
            if speechSynthesizer.isSpeaking {
                speechSynthesizer.pauseSpeaking(at: .word)
            }
            
        case .ended:
            // 中断结束
            if let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt {
                // 修复：将 AVAudioSession.InterruptionOptions 作为非可选类型使用
                let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
                if options.contains(.shouldResume) {
                    // 如果应该恢复播放
                    if speechSynthesizer.isPaused {
                        speechSynthesizer.continueSpeaking()
                    } else {
                        // 处理队列
                        processQueue()
                    }
                }
            }
            
        @unknown default:
            break
        }
    }
    
    // 添加语音可用性验证
    private func verifyVoiceAvailability() {
        // 检查当前选择的语音是否可用
        let isVoiceAvailable = AVSpeechSynthesisVoice(language: voiceLanguage) != nil
        
        if !isVoiceAvailable {
            // 尝试使用语言前缀
            let languagePrefix = VoiceLanguageCode.getPrefix(from: voiceLanguage)
            let isPrefixAvailable = AVSpeechSynthesisVoice(language: languagePrefix) != nil
            
            if isPrefixAvailable {
                // 使用语言前缀
                voiceLanguage = languagePrefix
               
                
                // 保存更新后的设置
                let defaults = UserDefaults.standard
                defaults.set(languagePrefix, forKey: "voice_language")
            } else {
                // 使用英语作为最后的回退选项
                voiceLanguage = VoiceLanguageCode.english
             
                
                // 保存更新后的设置
                let defaults = UserDefaults.standard
                defaults.set(VoiceLanguageCode.english, forKey: "voice_language")
            }
        }
    }
    
    // 添加应用状态处理方法
    @objc private func handleAppDidEnterBackground() {
        // 记录进入后台的时间
        backgroundDate = Date()
        
        // 暂停当前播报
        if speechSynthesizer.isSpeaking {
            speechSynthesizer.pauseSpeaking(at: .word)
        }
    }
    
    @objc private func handleAppWillEnterForeground() {
        // 如果有记录的后台时间
        if let date = backgroundDate {
            // 计算在后台的时间
            let timeInBackground = Date().timeIntervalSince(date)
            
            // 如果在后台时间不长（小于30秒），继续播报
            if timeInBackground < 30 && speechSynthesizer.isPaused {
                speechSynthesizer.continueSpeaking()
            } else {
                // 如果在后台时间较长，清空队列并重新开始
                speechSynthesizer.stopSpeaking(at: .immediate)
                speechQueue.removeAll()
                isProcessingQueue = false
            }
            
            // 重置后台时间
            backgroundDate = nil
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        
        isVoiceEnabled = defaults.bool(forKey: "voice_enabled")
        if defaults.object(forKey: "voice_enabled") == nil {
            isVoiceEnabled = true
        }
        
        voiceRate = defaults.float(forKey: "voice_rate")
        if voiceRate == 0 {
            voiceRate = 0.5
        }
        
        voiceVolume = defaults.float(forKey: "voice_volume")
        if voiceVolume == 0 {
            voiceVolume = 1.0
        }
        
        if let language = defaults.string(forKey: "voice_language") {
            // 支持的语言列表
            let supportedLanguages = ["en-US", "zh-CN", "ja-JP", "ko-KR"]
            if supportedLanguages.contains(language) {
                voiceLanguage = language
            } else {
                voiceLanguage = "en-US"
                defaults.set("en-US", forKey: "voice_language")
            }
        }
    }
    
    func updateSettings(rate: Float, language: String, volume: Float, enabled: Bool) {
        voiceRate = rate
        voiceLanguage = language
        voiceVolume = volume
        isVoiceEnabled = enabled
        
        let defaults = UserDefaults.standard
        defaults.set(rate, forKey: "voice_rate")
        defaults.set(language, forKey: "voice_language")
        defaults.set(volume, forKey: "voice_volume")
        defaults.set(enabled, forKey: "voice_enabled")
        
        // 更新消息格式化工具的语言设置
        if let formatter = NSClassFromString("VoiceMessageFormatter") as? NSObject.Type,
           let shared = formatter.value(forKey: "shared") as? NSObject,
           shared.responds(to: Selector("updateFormatters")) {
            shared.perform(Selector("updateFormatters"))
        }
    }
    
    func speak(_ text: String, priority: SpeechPriority = .normal) {
        guard isVoiceEnabled else { return }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voiceRate
        
        // 改进语音选择逻辑
        var voiceFound = false
        
        // 尝试使用完整语言代码
        if let voice = AVSpeechSynthesisVoice(language: voiceLanguage) {
            utterance.voice = voice
            voiceFound = true
        } else {
            // 尝试使用语言前缀
            let languagePrefix = VoiceLanguageCode.getPrefix(from: voiceLanguage)
            if let fallbackVoice = AVSpeechSynthesisVoice(language: languagePrefix) {
                utterance.voice = fallbackVoice
                voiceFound = true
                
            }
        }
        
        // 如果仍然找不到，使用系统默认语音
        if !voiceFound {
            // 尝试使用英语作为最后的回退选项
            if let defaultVoice = AVSpeechSynthesisVoice(language: VoiceLanguageCode.english) {
                utterance.voice = defaultVoice
            }
        }
        
        utterance.volume = voiceVolume
        
        // 根据优先级处理
        switch priority {
        case .high:
            // 高优先级：停止当前播报，清空队列，立即播报
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            speechSynthesizer.speak(utterance)
        case .normal:
            // 普通优先级：如果没有播报则立即播报，否则加入队列
            if !speechSynthesizer.isSpeaking {
                speechSynthesizer.speak(utterance)
            } else {
                // 限制队列长度，避免内存问题
                if speechQueue.count < 5 {
                    speechQueue.append(utterance)
                } else {
                    // 移除最旧的非高优先级消息
                    if let index = speechQueue.firstIndex(where: { $0.preUtteranceDelay < 0.1 }) {
                        speechQueue.remove(at: index)
                        speechQueue.append(utterance)
                    }
                }
            }
        case .low:
            // 低优先级：只有在没有播报且队列为空时才播报，否则忽略
            if !speechSynthesizer.isSpeaking && speechQueue.isEmpty {
                speechSynthesizer.speak(utterance)
            } else {
                // 低优先级不加入队列，直接忽略
            }
        }
        
        // 如果没有正在处理的队列，开始处理
        if !isProcessingQueue && !speechQueue.isEmpty && !speechSynthesizer.isSpeaking {
            processQueue()
        }
        
        
        
        
    }
    
    // 优化队列处理方法
    private func processQueue() {
        guard !isProcessingQueue, !speechQueue.isEmpty, !speechSynthesizer.isSpeaking else {
            return
        }
        
        isProcessingQueue = true
        let utterance = speechQueue.removeFirst()
        speechSynthesizer.speak(utterance)
    }

    // 完善语音合成器代理方法
    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        // 处理队列
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isProcessingQueue = false
            self.processQueue()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        // 处理语音取消的情况
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isProcessingQueue = false
            self.processQueue()
        }
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didPause utterance: AVSpeechUtterance) {
        // 处理语音暂停的情况
        isProcessingQueue = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didContinue utterance: AVSpeechUtterance) {
        // 处理语音继续的情况
        isProcessingQueue = true
    }
    
    // MARK: - 语音播报方法
    // 修改 announceCurrentStatus 方法，使用更适合 iOS 的方式添加停顿
    func announceCurrentStatus(speed: Double, distance: Double, duration: TimeInterval, calories: Double) {
        guard isVoiceEnabled else { return }
        
        var messages = [String]()
        let defaults = UserDefaults.standard
        let messageFormatter = VoiceMessageFormatter.shared
        
        // 将各项内容分开存储，而不是拼接成一个字符串
        if defaults.bool(forKey: "announce_speed") {
            messages.append(messageFormatter.formatSpeedMessage(speed: speed))
        }
        
        if defaults.bool(forKey: "announce_distance") {
            messages.append(messageFormatter.formatDistanceMessage(distance: distance))
        }
        
        if defaults.bool(forKey: "announce_time") {
            messages.append(messageFormatter.formatTimeMessage(duration: duration))
        }
        
        if defaults.bool(forKey: "announce_calories") {
            messages.append(messageFormatter.formatCaloriesMessage(calories: calories))
        }
        
        // 逐个播报，使用 preUtteranceDelay 添加停顿
        speakSequentially(messages)
    }


    // 优化 speakSequentially 方法
    func speakSequentially(_ messages: [String], priority: SpeechPriority = .normal) {
        guard isVoiceEnabled, !messages.isEmpty else { return }
        
        // 如果是高优先级，先清空当前播报和队列
        if priority == .high {
            speechSynthesizer.stopSpeaking(at: .immediate)
            speechQueue.removeAll()
            isProcessingQueue = false
        } else if speechSynthesizer.isSpeaking {
            // 如果正在播报且不是高优先级，则加入队列后返回
            if speechQueue.count + messages.count > 10 {
                // 如果队列过长，只保留最新的消息
                speechQueue = Array(speechQueue.prefix(5))
            }
            
            for message in messages {
                let utterance = createUtterance(message)
                utterance.preUtteranceDelay = 0.8 // 添加0.8秒停顿
                speechQueue.append(utterance)
            }
            return
        }
        
        // 创建并播报第一条消息
        let firstUtterance = createUtterance(messages[0])
        speechSynthesizer.speak(firstUtterance)
        
        // 将剩余消息添加到队列
        for i in 1..<messages.count {
            let utterance = createUtterance(messages[i])
            utterance.preUtteranceDelay = 0.8 // 添加0.8秒停顿
            speechQueue.append(utterance)
        }
        
        // 确保队列处理标志正确设置
        isProcessingQueue = true
    }

    // 创建语音合成对象的辅助方法
    private func createUtterance(_ text: String) -> AVSpeechUtterance {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = voiceRate
        
        if let voice = AVSpeechSynthesisVoice(language: voiceLanguage) {
            utterance.voice = voice
        } else {
            let languagePrefix = VoiceLanguageCode.getPrefix(from: voiceLanguage)
            if let fallbackVoice = AVSpeechSynthesisVoice(language: languagePrefix) {
                utterance.voice = fallbackVoice
            }
        }
        
        utterance.volume = voiceVolume
        return utterance
    }
    
    func announceSpeed(_ speed: Double, unit: String = "km/h") {
        guard isVoiceEnabled else { return }
        
        let speedKey = VoiceLocalizationManager.shared.localizedString(for: "speed")
        let speedMessage = String(format: "%@: %.1f %@", speedKey, speed, unit)
        speak(speedMessage, priority: .normal)
    }
    
    func announceDistance(_ distance: Double, unit: String = "kilometers") {
        guard isVoiceEnabled else { return }
        
        let distanceKey = VoiceLocalizationManager.shared.localizedString(for: "distance")
        let distanceMessage = String(format: "%@: %.2f %@", distanceKey, distance, unit)
        speak(distanceMessage, priority: .normal)
    }
    
    func announceTime(_ seconds: Int) {
        guard isVoiceEnabled else { return }
        
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let remainingSeconds = seconds % 60
        
        let timeKey = VoiceLocalizationManager.shared.localizedString(for: "time")
        var timeMessage = "\(timeKey): "
        if hours > 0 {
            timeMessage += "\(hours) hours "
        }
        if minutes > 0 || hours > 0 {
            timeMessage += "\(minutes) minutes "
        }
        timeMessage += "\(remainingSeconds) seconds"
        
        speak(timeMessage, priority: .normal)
    }
    
    func announceCalories(_ calories: Double) {
        guard isVoiceEnabled else { return }
        
        let caloriesKey = VoiceLocalizationManager.shared.localizedString(for: "calories")
        let caloriesMessage = String(format: "%@: %.0f", caloriesKey, calories)
        speak(caloriesMessage, priority: .normal)
    }
    
    func announceSummary(speed: Double? = nil, distance: Double? = nil, time: Int? = nil, calories: Double? = nil) {
        guard isVoiceEnabled else { return }
        
        let localizationManager = VoiceLocalizationManager.shared
        var summaryMessage = "Summary: "
        
        if let speed = speed {
            let speedKey = localizationManager.localizedString(for: "speed")
            summaryMessage += String(format: "%@ %.1f kilometers per hour. ", speedKey, speed)
        }
        
        if let distance = distance {
            let distanceKey = localizationManager.localizedString(for: "distance")
            summaryMessage += String(format: "%@ %.2f kilometers. ", distanceKey, distance)
        }
        
        if let time = time {
            let timeKey = localizationManager.localizedString(for: "time")
            let hours = time / 3600
            let minutes = (time % 3600) / 60
            let seconds = time % 60
            
            summaryMessage += "\(timeKey) "
            if hours > 0 {
                summaryMessage += "\(hours) hours "
            }
            if minutes > 0 || hours > 0 {
                summaryMessage += "\(minutes) minutes "
            }
            summaryMessage += "\(seconds) seconds. "
        }
        
        if let calories = calories {
            let caloriesKey = localizationManager.localizedString(for: "calories")
            summaryMessage += String(format: "%@ %.0f.", caloriesKey, calories)
        }
        
        speak(summaryMessage, priority: .normal)
    }
    
    // 清理资源
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
