import SwiftUI
import Charts

struct RideHealthView: View {
    @StateObject private var viewModel = RideHealthViewModel()
    @State private var showingWeightPicker = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                HStack {
                    Text("Health Data")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // Removed time range selector, only showing this week's data
                    Text("This Week's Data")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Weight range selector
                HStack {
                    Text("Weight Range")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        showingWeightPicker = true
                    }) {
                        HStack {
                            Text(viewModel.selectedWeightRange.rawValue)
                                .foregroundColor(.primary)
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
                .actionSheet(isPresented: $showingWeightPicker) {
                    ActionSheet(
                        title: Text("Select Weight Range"),
                        buttons: WeightRange.allCases.map { range in
                            .default(Text(range.rawValue)) {
                                viewModel.selectedWeightRange = range
                            }
                        } + [.cancel(Text("Cancel"))]
                    )
                }
                
                // Health data cards
                VStack(spacing: 16) {
                    // Calories burned card
                    healthMetricCard(
                        title: "Calories Burned",
                        value: viewModel.formattedCaloriesBurned,
                        changeRate: viewModel.caloriesChangeRate,
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    // Active time card
                    healthMetricCard(
                        title: "Active Time",
                        value: viewModel.formattedActiveTime,
                        changeRate: viewModel.activeTimeChangeRate,
                        icon: "clock.fill",
                        color: .blue
                    )
                }
                .padding(.horizontal)
                
                // Calories chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Calories Burned Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.caloriesData.isEmpty {
                        Text("No Data Available")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Weekly calories chart
                        weeklyChart(
                            data: viewModel.caloriesData,
                            valueLabel: "Calories",
                            color: .orange,
                            yAxisFormat: "%.0f"
                        )
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
                
                // Active time chart
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Time Trend")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else if viewModel.activeTimeData.isEmpty {
                        Text("No Data Available")
                            .foregroundColor(.secondary)
                            .frame(height: 200)
                            .frame(maxWidth: .infinity)
                    } else {
                        // Weekly active time chart
                        weeklyChart(
                            data: viewModel.activeTimeData,
                            valueLabel: "Minutes",
                            color: .blue,
                            yAxisFormat: "%.0f"
                        )
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                }
                
                // Health insights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Health Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.healthInsights.isEmpty {
                        Text("No Health Insights Available")
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    } else {
                        ForEach(viewModel.healthInsights) { insight in
                            insightCard(insight: insight)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Health Data")
        .onAppear {
            viewModel.loadData()
        }
    }
    
    // Health metric card
    private func healthMetricCard(title: String, value: String, changeRate: Double?, icon: String, color: Color) -> some View {
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
    
    // Weekly chart view
    private func weeklyChart(data: [HealthMetricPoint], valueLabel: String, color: Color, yAxisFormat: String) -> some View {
           Chart {
               ForEach(data) { point in
                   BarMark(
                       x: .value("Date", formatWeekdayShort(from: point.date)),
                       y: .value(valueLabel, point.value)
                   )
                   .foregroundStyle(color.gradient)
               }
           }
           // Key modification: Set Y-axis domain range to ensure reasonable scale even without data
           .chartYScale(domain: yAxisDomainFromZero(data: data, valueLabel: valueLabel))
           .chartYAxis {
               // Modify Y-axis display, add incremental units
               AxisMarks(preset: .automatic, position: .leading, values: .automatic(desiredCount: 5)) { value in
                   AxisGridLine()
                   AxisValueLabel {
                       if let doubleValue = value.as(Double.self) {
                           Text(String(format: yAxisFormat, doubleValue) + (valueLabel == "Calories" ? " kcal" : " min"))
                               .font(.caption)
                       }
                   }
               }
           }
           .chartXAxis {
               AxisMarks { value in
                   AxisValueLabel {
                       if let dateString = value.as(String.self) {
                           Text(dateString)
                               .font(.caption)
                       }
                   }
               }
           }
           .padding()
           .background(Color(UIColor.secondarySystemBackground))
           .cornerRadius(12)
       }
       
       // Add method to calculate Y-axis domain range, ensuring reasonable scale even without data
       private func yAxisDomainFromZero(data: [HealthMetricPoint], valueLabel: String) -> ClosedRange<Double> {
           let values = data.map { $0.value }
           
           // Always start from 0
           let minValue = 0.0
           // Find maximum value, if max is too small or no data, use default value
           let maxValue = values.max() ?? 0
           
           // Set different minimum display ranges for different metrics
           let minDisplayValue: Double
           if valueLabel == "Calories" {
               minDisplayValue = 100 // At least show range of 100 calories
           } else {
               minDisplayValue = 30 // At least show range of 30 minutes
           }
           
           // If max value is too small or no data, use a reasonable default range
           if maxValue < minDisplayValue {
               return 0...minDisplayValue
           }
           
           // Add top padding to ensure data points aren't at the very top
           let padding = maxValue * 0.2
           let upperBound = maxValue + padding
           
           return minValue...upperBound
       }
    
    // Format date to short weekday format (e.g., Mon, Tue)
    private func formatWeekdayShort(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E" // Short weekday format
        formatter.locale = Locale(identifier: "en_US") // Use English
        return formatter.string(from: date)
    }
    
    // Health insight card
    private func insightCard(insight: HealthInsight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            Image(systemName: insightIconName(for: insight.type))
                .foregroundColor(insight.isPositive ? .green : .orange)
                .font(.title3)
                .frame(width: 24, height: 24)
            
            // Insight content
            Text(insight.message)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // Return icon name based on insight type
    private func insightIconName(for type: HealthInsightType) -> String {
        switch type {
        case .caloriesBurned:
            return "flame.fill"
        case .ridingFrequency:
            return "calendar"
        case .activityLevel:
            return "figure.walk"
        case .consistency:
            return "chart.bar.fill"
        }
    }
}
