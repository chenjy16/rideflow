import Foundation

struct DailyRideSummary: Identifiable {
    let id = UUID()
    let date: Date
    let distance: Double
    let avgSpeed: Double
    let duration: TimeInterval
    let elevationGain: Double
    
    func formattedDate() -> String {
       let formatter = DateFormatter()
       formatter.dateFormat = "yyyy-MM-dd"
       return formatter.string(from: date)
   }
}
