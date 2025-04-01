import Foundation

class VoiceMessageFormatter {
    static let shared = VoiceMessageFormatter()
    
    private var locale: Locale {
        let language = UserDefaults.standard.string(forKey: "voice_language") ?? "en-US"
        return Locale(identifier: language)
    }
    
    private let distanceFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    private let speedFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.unitStyle = .medium
        formatter.numberFormatter.maximumFractionDigits = 1
        return formatter
    }()
    
    private let durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .full
        formatter.maximumUnitCount = 2
        return formatter
    }()
    
    private init() {
        updateFormatters()
    }
    
    func updateFormatters() {
        distanceFormatter.locale = locale
        speedFormatter.locale = locale
        durationFormatter.calendar = Calendar(identifier: .gregorian)
        durationFormatter.calendar?.locale = locale
    }
    
    func formatSpeedMessage(speed: Double, unit: UnitSpeed = .kilometersPerHour) -> String {
        let language = UserDefaults.standard.string(forKey: "voice_language") ?? "en-US"
        
        // 根据不同语言返回适当的格式，添加更完整的描述
        if language.starts(with: "zh") {
            return String(format: "当前速度: %.1f 公里每小时", speed)
        } else if language.starts(with: "ja") {
            return String(format: "現在の速度は 時速 %.1f キロメートルです", speed)
        } else if language.starts(with: "ko") {
            return String(format: "현재 속도는 시속 %.1f 킬로미터입니다", speed)
        } else {
            return String(format: "Current speed: %.1f kilometers per hour", speed)
        }
    }

    func formatDistanceMessage(distance: Double, unit: UnitLength = .kilometers) -> String {
        let language = UserDefaults.standard.string(forKey: "voice_language") ?? "en-US"
        
        // 根据不同语言返回适当的格式，添加更完整的描述
        if language.starts(with: "zh") {
            return String(format: "骑行总距离: %.1f 公里", distance)
        } else if language.starts(with: "ja") {
            return String(format: "総走行距離は %.1f キロメートルです", distance)
        } else if language.starts(with: "ko") {
            return String(format: "총 주행 거리는 %.1f 킬로미터입니다", distance)
        } else {
            return String(format: "Total distance: %.1f kilometers", distance)
        }
    }
    
    // 添加或修改时间格式化方法
    func formatTimeMessage(duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        
        let language = UserDefaults.standard.string(forKey: "voice_language") ?? "en-US"
        
        // 根据不同语言返回适当的格式，添加更完整的描述
        if language.starts(with: "zh") {
            var timeString = "骑行持续时间: "
            if hours > 0 {
                timeString += "\(hours)小时"
            }
            if minutes > 0 || hours > 0 {
                timeString += "\(minutes)分钟"
            }
            timeString += "\(seconds)秒"
            return timeString
        } else if language.starts(with: "ja") {
            var timeString = "走行時間は "
            if hours > 0 {
                timeString += "\(hours)時間"
            }
            if minutes > 0 || hours > 0 {
                timeString += "\(minutes)分"
            }
            timeString += "\(seconds)秒です"
            return timeString
        } else if language.starts(with: "ko") {
            var timeString = "주행 시간은 "
            if hours > 0 {
                timeString += "\(hours)시간 "
            }
            if minutes > 0 || hours > 0 {
                timeString += "\(minutes)분 "
            }
            timeString += "\(seconds)초입니다"
            return timeString
        } else {
            var timeString = "Riding duration: "
            if hours > 0 {
                timeString += "\(hours) hours "
            }
            if minutes > 0 || hours > 0 {
                timeString += "\(minutes) minutes "
            }
            timeString += "\(seconds) seconds"
            return timeString
        }
    }
    
    // 添加或修改卡路里格式化方法
    func formatCaloriesMessage(calories: Double) -> String {
        let language = UserDefaults.standard.string(forKey: "voice_language") ?? "en-US"
        
        // 根据不同语言返回适当的格式，添加更完整的描述
          if language.starts(with: "zh") {
              return String(format: "消耗的卡路里: %.0f 卡", calories)
          } else if language.starts(with: "ja") {
              return String(format: "消費カロリーは %.0f カロリーです", calories)
          } else if language.starts(with: "ko") {
              return String(format: "소모된 칼로리는 %.0f 칼로리입니다", calories)
          } else {
              return String(format: "Calories burned: %.0f calories", calories)
          }
    }
    

}
