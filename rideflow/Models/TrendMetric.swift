enum TrendMetric {
    case distance
    case speed
    case duration
    case elevation
    
    var localizedTitle: String {
        switch self {
        case .distance: return "Distance"
        case .speed: return "Speed"
        case .duration: return "Time"
        case .elevation: return "Climb"
        }
    }
    
    var unitLabel: String {
        switch self {
        case .distance: return "km"
        case .speed: return "km/h"
        case .duration: return "hours"
        case .elevation: return "meters" 
        }
    }
    
    func formatValue(_ value: Double) -> String {
        switch self {
        case .distance, .speed, .elevation:
            return String(format: "%.1f", value)
        case .duration:
            return String(format: "%.1f", value)
        }
    }
}
