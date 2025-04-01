import Foundation

// Weight Range
enum WeightRange: String, CaseIterable, Identifiable {
    case light = "Light (50-60kg)"
    case medium = "Medium (60-75kg)"
    case heavy = "Heavy (75-90kg)"
    case veryHeavy = "Very Heavy (90kg+)"
    
    var id: String { self.rawValue }
    
    var middleValue: Double {
        switch self {
        case .light:
            return 55.0
        case .medium:
            return 67.5
        case .heavy:
            return 82.5
        case .veryHeavy:
            return 95.0
        }
    }
}
