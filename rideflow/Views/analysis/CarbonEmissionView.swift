import SwiftUI
import Charts

struct CarbonEmissionView: View {
    @StateObject private var viewModel = CarbonEmissionViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Text("Carbon Tracking")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Show only current week data
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Carbon overview card
                carbonOverviewCard
                
                // Carbon savings trend chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Carbon Savings Trend")
                        .font(.headline)
                    
                    carbonSavedChart
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(10)
                .padding(.horizontal)
                
                // Transportation comparison
                transportComparisonSection
                
                // Environmental achievements
                environmentalAchievementsSection
            }
            .padding(.vertical)
        }
        .navigationTitle("Carbon Tracking")
        .overlay(
            Group {
                if viewModel.isLoading {
                    ProgressView("Loading...")
                        .padding()
                        .background(Color(UIColor.systemBackground).opacity(0.8))
                        .cornerRadius(10)
                }
            }
        )
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // Carbon overview card
    private var carbonOverviewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Carbon Savings Overview")
                .font(.headline)
            
            HStack(spacing: 20) {
                // Total carbon saved
                VStack(alignment: .leading, spacing: 5) {
                    Text("Total Saved")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    if viewModel.totalCarbonSaved < 1000 {
                        Text("\(Int(viewModel.totalCarbonSaved))g")
                            .font(.title2)
                            .fontWeight(.bold)
                    } else {
                        Text(String(format: "%.2fkg", viewModel.totalCarbonSaved / 1000.0))
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                
                Divider()
                    .frame(height: 40)
                
                // Environmental impact
                VStack(alignment: .leading, spacing: 5) {
                    Text("Environmental Impact")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.environmentalBenefitDescription)
                        .font(.callout)
                        .fontWeight(.medium)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.systemBackground))
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding(.horizontal)
    }
    
    // Carbon savings chart
    private var carbonSavedChart: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
                    .frame(height: 250)
            } else if viewModel.carbonSavedData.isEmpty {
                // Empty chart state
                emptyChartView
            } else {
                // Chart with data
                dataChartView
            }
        }
        .frame(maxWidth: .infinity)
    }

    // Empty chart view
    private var emptyChartView: some View {
        Chart {
            // Empty data point for axis display
            LineMark(
                x: .value("Date", Date()),
                y: .value("Emissions", 0)
            )
            .opacity(0)
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 7)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(formatWeekdayShort(from: date))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.0fg", doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: 0...100)
        .overlay(
            Text("No Data Available")
                .foregroundColor(.secondary)
        )
    }

    // Data chart view
    private var dataChartView: some View {
        Chart {
            ForEach(viewModel.carbonSavedData) { dataPoint in
                LineMark(
                    x: .value("Date", formatWeekdayShort(from: dataPoint.date)),
                    y: .value("Emissions", dataPoint.value)
                )
                .foregroundStyle(Color.green.gradient)
                .interpolationMethod(.catmullRom)
                
                AreaMark(
                    x: .value("Date", formatWeekdayShort(from: dataPoint.date)),
                    y: .value("Emissions", dataPoint.value)
                )
                .foregroundStyle(Color.green.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
        }
        .frame(height: 250)
        .chartXAxis {
            AxisMarks { value in
                AxisGridLine()
                AxisValueLabel {
                    if let dateString = value.as(String.self) {
                        Text(dateString)
                            .font(.caption)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let doubleValue = value.as(Double.self) {
                        Text(String(format: "%.0fg", doubleValue))
                            .font(.caption)
                    }
                }
            }
        }
        .chartYScale(domain: yAxisDomainFromZero())
    }
    
    private func yAxisDomainFromZero() -> ClosedRange<Double> {
        let values = viewModel.carbonSavedData.map { $0.value }
        let minValue = 0.0
        let maxValue = values.max() ?? 0
        let minDisplayValue = 100.0
        
        if maxValue < minDisplayValue {
            return 0...minDisplayValue
        }
        
        let padding = maxValue * 0.2
        let upperBound = maxValue + padding
        
        return minValue...upperBound
    }
    
    private func formatWeekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: date)
    }
    
    private var transportComparisonSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Transportation Comparison")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    transportCard(
                        icon: "bicycle",
                        title: "Bicycle",
                        emission: "0g/km",
                        color: .green
                    )
                    
                    transportCard(
                        icon: "bus.fill",
                        title: "Public Transit",
                        emission: "~30g/km",
                        color: .blue
                    )
                    
                    transportCard(
                        icon: "car.fill",
                        title: "Car",
                        emission: "~120g/km",
                        color: .orange
                    )
                    
                    transportCard(
                        icon: "scooter",
                        title: "Motorcycle",
                        emission: "~70g/km",
                        color: .purple
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func transportCard(icon: String, title: String, emission: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
            
            Text(emission)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(width: 120, height: 120)
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var environmentalAchievementsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Environmental Achievements")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 15) {
                achievementCard(
                    title: "Weekly Carbon Savings",
                    value: viewModel.formattedCarbonSaved,
                    changeRate: viewModel.carbonSavedChangeRate,
                    icon: "leaf.fill",
                    color: .green
                )
                
                achievementCard(
                    title: "Equivalent to Planting",
                    value: String(format: "%.2f trees", viewModel.periodCarbonSaved / 7000),
                    changeRate: nil,
                    icon: "tree.fill",
                    color: .green
                )
                
                achievementCard(
                    title: "Driving Reduction Equivalent",
                    value: String(format: "%.1f km", viewModel.periodCarbonSaved / 120),
                    changeRate: nil,
                    icon: "car.fill",
                    color: .blue
                )
            }
            .padding(.horizontal)
        }
    }
    
    private func achievementCard(title: String, value: String, changeRate: Double?, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if let rate = changeRate {
                HStack(spacing: 2) {
                    Image(systemName: rate >= 0 ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(rate >= 0 ? .green : .red)
                    
                    Text(String(format: "%.0f%%", abs(rate)))
                        .font(.subheadline)
                        .foregroundColor(rate >= 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}
