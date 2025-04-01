import Foundation


// 添加语言代码常量
struct VoiceLanguageCode {
    static let english = "en-US"
    static let chineseSimplified = "zh-CN"
    static let chineseTraditional = "zh-TW"
    static let japanese = "ja-JP"
    static let korean = "ko-KR"
    
    // 获取简化的语言代码前缀
    static func getPrefix(from code: String) -> String {
        return String(code.prefix(2))
    }
    
    // 获取当前系统语言的最佳匹配
    static func getBestMatch() -> String {
        let preferredLanguage = Locale.preferredLanguages.first ?? "en-US"
        let prefix = getPrefix(from: preferredLanguage)
        
        switch prefix {
        case "zh":
            // 根据地区区分繁体/简体
            if preferredLanguage.contains("TW") || preferredLanguage.contains("HK") {
                return preferredLanguage.contains("TW") ? chineseTraditional : "zh-HK"
            } else {
                return chineseSimplified
            }
        case "ja":
            return japanese
        case "ko":
            return korean
        default:
            return english
        }
    }
}


class VoiceLocalizationManager {
    static let shared = VoiceLocalizationManager()

    // 使用常量替代硬编码的语言代码
    private var currentLanguage: String {
        return UserDefaults.standard.string(forKey: "voice_language") ?? VoiceLanguageCode.getBestMatch()
    }
    
    private init() {}
    
    // 获取本地化字符串
    func localizedString(for key: String) -> String {
        switch key {
        // 运动状态相关
        case "workout_started":
            return localizedWorkoutStarted()
        case "workout_paused":
            return localizedWorkoutPaused()
        case "workout_resumed":
            return localizedWorkoutResumed()
        case "workout_completed":
            return localizedWorkoutCompleted()
            
        // 数据类型相关
        case "kilometers":
            return localizedKilometers()
        case "kilometers_per_hour":
            return localizedKilometersPerHour()
        case "hours":
            return localizedHours()
        case "minutes":
            return localizedMinutes()
        case "distance":
            return localizedDistance()
        case "speed":
            return localizedSpeed()
        case "time":
            return localizedTime()
        case "calories":
            return localizedCalories()
        case "milestone":
            return localizedMilestone()
            
        // 默认返回空字符串
        default:
            return ""
        }
    }
    
    // 运动状态本地化
    private func localizedWorkoutStarted() -> String {
        if currentLanguage.starts(with: "zh") {
            return "开始运动"
        } else if currentLanguage.starts(with: "en") {
            return "Workout started"
        } else if currentLanguage.starts(with: "ja") {
            return "運動を開始します"
        } else if currentLanguage.starts(with: "ko") {
            return "운동 시작"
        } else {
            return "Workout started"
        }
    }
    
    private func localizedWorkoutPaused() -> String {
        if currentLanguage.starts(with: "zh") {
            return "运动已暂停"
        } else if currentLanguage.starts(with: "en") {
            return "Workout paused"
        } else if currentLanguage.starts(with: "ja") {
            return "運動を一時停止しました"
        } else if currentLanguage.starts(with: "ko") {
            return "운동 일시 중지"
        } else {
            return "Workout paused"
        }
    }
    
    private func localizedWorkoutResumed() -> String {
        if currentLanguage.starts(with: "zh") {
            return "继续运动"
        } else if currentLanguage.starts(with: "en") {
            return "Workout resumed"
        } else if currentLanguage.starts(with: "ja") {
            return "運動を再開します"
        } else if currentLanguage.starts(with: "ko") {
            return "운동 재개"
        } else {
            return "Workout resumed"
        }
    }
    
    private func localizedWorkoutCompleted() -> String {
        if currentLanguage.starts(with: "zh") {
            return "运动结束"
        } else if currentLanguage.starts(with: "en") {
            return "Workout completed"
        } else if currentLanguage.starts(with: "ja") {
            return "運動が終了しました"
        } else if currentLanguage.starts(with: "ko") {
            return "운동 완료"
        } else {
            return "Workout completed"
        }
    }
    
    // 数据类型本地化
    private func localizedDistance() -> String {
        if currentLanguage.starts(with: "zh") {
            return "距离"
        } else if currentLanguage.starts(with: "en") {
            return "Distance"
        } else if currentLanguage.starts(with: "ja") {
            return "距離"
        } else if currentLanguage.starts(with: "ko") {
            return "거리"
        } else {
            return "Distance"
        }
    }
    
    private func localizedSpeed() -> String {
        if currentLanguage.starts(with: "zh") {
            return "速度"
        } else if currentLanguage.starts(with: "en") {
            return "Speed"
        } else if currentLanguage.starts(with: "ja") {
            return "速度"
        } else if currentLanguage.starts(with: "ko") {
            return "속도"
        } else {
            return "Speed"
        }
    }
    
    private func localizedTime() -> String {
        if currentLanguage.starts(with: "zh") {
            return "时间"
        } else if currentLanguage.starts(with: "en") {
            return "Time"
        } else if currentLanguage.starts(with: "ja") {
            return "時間"
        } else if currentLanguage.starts(with: "ko") {
            return "시간"
        } else {
            return "Time"
        }
    }
    
    private func localizedCalories() -> String {
        if currentLanguage.starts(with: "zh") {
            return "卡路里"
        } else if currentLanguage.starts(with: "en") {
            return "Calories"
        } else if currentLanguage.starts(with: "ja") {
            return "カロリー"
        } else if currentLanguage.starts(with: "ko") {
            return "칼로리"
        } else {
            return "Calories"
        }
    }
    
    private func localizedMilestone() -> String {
        if currentLanguage.starts(with: "zh") {
            return "里程碑"
        } else if currentLanguage.starts(with: "en") {
            return "Milestone"
        } else if currentLanguage.starts(with: "ja") {
            return "マイルストーン"
        } else if currentLanguage.starts(with: "ko") {
            return "이정표"
        } else {
            return "Milestone"
        }
    }
    
    
    private func localizedKilometers() -> String {
        if currentLanguage.starts(with: "zh") {
            return "公里"
        } else if currentLanguage.starts(with: "ja") {
            return "キロメートル"
        } else if currentLanguage.starts(with: "ko") {
            return "킬로미터"
        } else {
            return "kilometers"
        }
    }

    private func localizedKilometersPerHour() -> String {
        if currentLanguage.starts(with: "zh") {
            return "公里每小时"
        } else if currentLanguage.starts(with: "ja") {
            return "キロメートル毎時"
        } else if currentLanguage.starts(with: "ko") {
            return "킬로미터 매시"
        } else {
            return "kilometers per hour"
        }
    }

    private func localizedHours() -> String {
        if currentLanguage.starts(with: "zh") {
            return "小时"
        } else if currentLanguage.starts(with: "ja") {
            return "時間"
        } else if currentLanguage.starts(with: "ko") {
            return "시간"
        } else {
            return "hours"
        }
    }

    private func localizedMinutes() -> String {
        if currentLanguage.starts(with: "zh") {
            return "分钟"
        } else if currentLanguage.starts(with: "ja") {
            return "分"
        } else if currentLanguage.starts(with: "ko") {
            return "분"
        } else {
            return "minutes"
        }
    }

    
    
    
}
