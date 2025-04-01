import SwiftUI
import Injected

class VoiceSettingsViewModel: ObservableObject {
    
    @Injected private var voiceService: VoiceService
    
    @Published var isVoiceEnabled = false
    @Published var selectedLanguage = "en-US"  // 默认使用英语
    @Published var voiceRate: Float = 0.5
    @Published var voiceVolume: Float = 1.0

    @Published var announceSpeed = false
    @Published var announceDistance = false
    @Published var announceTime = false
    @Published var announceCalories = false
    @Published var announceMilestones = false
    @Published var announceEveryMinute: Bool = false
    @Published var announceEvery5Minutes: Bool = false
    @Published var announceEvery10Minutes: Bool = false
    
    // 只支持英语
    let availableLanguages = [
        LanguageOption(name: "English", code: "en-US"),
        LanguageOption(name: "中文", code: "zh-CN"),
        LanguageOption(name: "日本語", code: "ja-JP"),
        LanguageOption(name: "한국어", code: "ko-KR")
    ]
    
    init() {
        loadSettings()
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        
        // 基本设置
        isVoiceEnabled = defaults.bool(forKey: "voice_enabled")
        if defaults.object(forKey: "voice_enabled") == nil {
            isVoiceEnabled = false
        }
        
        if let language = defaults.string(forKey: "voice_language") {
              // 检查语言是否在支持列表中
              if availableLanguages.contains(where: { $0.code == language }) {
                  selectedLanguage = language
              } else {
                  selectedLanguage = "en-US"
                  defaults.set("en-US", forKey: "voice_language")
              }
          }
        
        voiceRate = defaults.float(forKey: "voice_rate")
        if voiceRate == 0 {
            voiceRate = 0.5
        }
        
        voiceVolume = defaults.float(forKey: "voice_volume")
        if voiceVolume == 0 {
            voiceVolume = 1.0
        }
        
        // 播报内容设置
        announceSpeed = defaults.bool(forKey: "announce_speed")
        if defaults.object(forKey: "announce_speed") == nil {
            announceSpeed = false
        }
        
        announceDistance = defaults.bool(forKey: "announce_distance")
        if defaults.object(forKey: "announce_distance") == nil {
            announceDistance = false
        }
        
        announceTime = defaults.bool(forKey: "announce_time")
        if defaults.object(forKey: "announce_time") == nil {
            announceTime = false
        }
        
        announceCalories = defaults.bool(forKey: "announce_calories")
        if defaults.object(forKey: "announce_calories") == nil {
            announceCalories = false
        }
        

        // 加载时间点播报设置
        announceEveryMinute = defaults.bool(forKey: "announce_every_minute")
        if defaults.object(forKey: "announce_every_minute") == nil {
            announceEveryMinute = false
        }
        
        announceEvery5Minutes = defaults.bool(forKey: "announce_every_5_minutes")
        if defaults.object(forKey: "announce_every_5_minutes") == nil {
            announceEvery5Minutes = false
        }
        
        announceEvery10Minutes = defaults.bool(forKey: "announce_every_10_minutes")
        if defaults.object(forKey: "announce_every_10_minutes") == nil {
            announceEvery10Minutes = false
        }
    }
    
    func saveSettings() {
        let defaults = UserDefaults.standard
        
        // 保存基本设置
        defaults.set(isVoiceEnabled, forKey: "voice_enabled")
        defaults.set(selectedLanguage, forKey: "voice_language")
        defaults.set(voiceRate, forKey: "voice_rate")
        defaults.set(voiceVolume, forKey: "voice_volume")
       
        // 保存播报内容设置
        defaults.set(announceSpeed, forKey: "announce_speed")
        defaults.set(announceDistance, forKey: "announce_distance")
        defaults.set(announceTime, forKey: "announce_time")
        defaults.set(announceCalories, forKey: "announce_calories")
     
       
        // 保存时间点播报设置
         defaults.set(announceEveryMinute, forKey: "announce_every_minute")
         defaults.set(announceEvery5Minutes, forKey: "announce_every_5_minutes")
         defaults.set(announceEvery10Minutes, forKey: "announce_every_10_minutes")
       
        // 更新语音服务设置
        voiceService.updateSettings(
            rate: voiceRate,
            language: selectedLanguage,
            volume: voiceVolume,
            enabled: isVoiceEnabled
        )
    }
    
    func previewVoice() {
        guard isVoiceEnabled else { return }
            
        // 根据当前选择的语言提供测试消息
        var testMessage = ""
            
        if selectedLanguage.starts(with: "zh") {
            testMessage = "这是一条测试消息。您可以调整语音速率和音量。"
        } else if selectedLanguage.starts(with: "ja") {
            testMessage = "これはテストメッセージです。音声の速度と音量を調整できます。"
        } else if selectedLanguage.starts(with: "ko") {
            testMessage = "이것은 테스트 메시지입니다. 음성 속도와 볼륨을 조정할 수 있습니다."
        } else {
            testMessage = "This is a test message. You can adjust speech rate and volume."
        }
        
        voiceService.speak(testMessage, priority: .high)
    }
}
