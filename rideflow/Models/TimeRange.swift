import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "This Week"

    var id: String { self.rawValue }
    
    var days: Int {
        switch self {
        case .week:
            return 7
        }
    }
    
    var previousPeriod: String {
        switch self {
        case .week:
            return "Previous Week"
        }
    }
}
