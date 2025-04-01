import SwiftUI

struct RideInsightsView: View {
    // Analysis type enum
    enum AnalysisType: String, CaseIterable, Identifiable {
        case trends = "Cycling Trends"
        case comparison = "Data Comparison"
        case health = "Health Data"
        case carbon = "Carbon Emission Analysis"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .trends: return "chart.line.uptrend.xyaxis"
            case .comparison: return "chart.bar.xaxis"
            case .health: return "flame.fill"
            case .carbon: return "leaf.fill"
            }
        }
        
        var description: String {
            switch self {
            case .trends: return "View your cycling distance, speed, and time trends."
            case .comparison: return "Compare cycling performance across different periods."
            case .health: return "View cycling's impact on health and calorie burn."
            case .carbon: return "Analyze your cycling contribution to reducing carbon emissions."
            }
        }
        
        var color: Color {
            switch self {
            case .trends: return .blue
            case .comparison: return .green
            case .health: return .orange
            case .carbon: return .green
            }
        }
    }
    

    @State private var searchText: String = ""
    @StateObject private var summaryViewModel = RideSummaryStatsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Top overview card
                    summaryCard
                    
                    // Analysis function grid
                    analysisGrid
                }
                .padding()
            }
            .navigationTitle("Cycling Analysis")
        }
        .onAppear {
            // Load overall statistics (unaffected by time range)
            summaryViewModel.loadTotalStats()
        }

    }
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Cycling Overview")
                .font(.headline)
            
            // Use a VStack to split the stats into two rows
            VStack(spacing: 16) {
                // First row: Total rides, Total distance, Total time
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Total rides
                        summaryItem(
                            title: "Total Rides",
                            value: "\(summaryViewModel.totalStats.rideCount)",
                            unit: "",
                            width: geometry.size.width / 3
                        )
                        
                        // Total distance
                        summaryItem(
                            title: "Total Distance",
                            value: String(format: "%.1f", summaryViewModel.totalStats.totalDistance),
                            unit: "km",
                            width: geometry.size.width / 3
                        )
                        
                  
                    }
                }
                .frame(height: 80) // Fixed height for the first row
                
                // Second row: Average speed, Total elevation
                GeometryReader { geometry in
                    HStack(spacing: 0) {
                        // Total time
                        summaryItem(
                            title: "Total Time",
                            value: formatDuration(summaryViewModel.totalStats.totalDuration),
                            unit: "",
                            width: geometry.size.width / 3,
                            isTime: true
                        )
                        
                        // Total elevation
                        summaryItem(
                            title: "Total Elevation",
                            value: String(format: "%.1f", summaryViewModel.totalStats.totalElevation),
                            unit: "m",
                            width: geometry.size.width / 2
                        )
                    }
                }
                .frame(height: 80) // Fixed height for the second row
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    // Unified view for overview stats
    private func summaryItem(title: String, value: String, unit: String, width: CGFloat, isTime: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if isTime {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: width, alignment: .leading)
    }

    // Time formatting function
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
   

    // Unified best record card view
    private func bestRecordCard(icon: String, iconColor: Color, title: String, value: Double, unit: String, date: Date, isTime: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 18))
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if isTime {
                // Special formatting for time values
                let hours = Int(value) / 60
                let minutes = Int(value) % 60
                Text("\(hours > 0 ? "\(hours)h " : "")\(minutes)m")
                    .font(.system(size: 24, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            } else {
                // Regular numerical display
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 24, weight: .bold))
                    Text(unit)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Text(timeAgoString(from: date))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, alignment: .leading)
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
    
    // Function to display relative time (e.g., "2h ago")
    private func timeAgoString(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Analysis function grid
    private var analysisGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("In-Depth Analysis")
                .font(.headline)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 15) {
                ForEach(AnalysisType.allCases) { type in
                    NavigationLink(destination: destinationView(for: type)) {
                        AnalysisCard(type: type)
                    }
                }
            }
        }
    }
    
    // Returns the destination view based on analysis type
    @ViewBuilder
    private func destinationView(for type: AnalysisType) -> some View {
        switch type {
        case .trends:
            RideTrendsView()
        case .comparison:
            RideComparisonView()
        case .health:
            RideHealthView()
        case .carbon:
            CarbonEmissionView() 
        }
    }
}

// Stat card component
struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Highlight card component
struct HighlightCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// Analysis card component
struct AnalysisCard: View {
    let type: RideInsightsView.AnalysisType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundColor(type.color)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(type.rawValue)
                .font(.headline)
            
            Text(type.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .frame(height: 130)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
