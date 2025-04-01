import SwiftUI
import Charts

struct RideComparisonView: View {
    @StateObject private var viewModel = RideComparisonViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title Section
                Text("Ride Comparison")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                
                // Ride Selection
                VStack(alignment: .leading) {
                    Text("Select Rides (max 10):")
                        .font(.headline)
                    
                    List {
                        ForEach(viewModel.availableRides) { ride in
                            HStack {
                                Image(systemName: viewModel.isSelected(ride) ? "checkmark.square.fill" : "square")
                                    .foregroundColor(viewModel.isSelected(ride) ? .blue : .gray)
                                
                                VStack(alignment: .leading) {
                                    Text(ride.name ?? "Unnamed Ride")
                                        .fontWeight(.medium)
                                    
                                    if let summary = ride.summary, let date = ride.createdAt {
                                        Text("\(date.formatted(date: .abbreviated, time: .shortened)) ")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.toggleRideSelection(ride)
                            }
                        }
                    }
                    .frame(height: 200)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Selection Counter
                Text("Selected \(viewModel.selectedRides.count) rides")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if viewModel.selectedRides.count >= 2 {
                    // Distance Chart
                    metricChartView(
                        title: "Distance Comparison (km)",
                        metricKey: "distance",
                        color: .blue
                    )
                    
                    // Speed Chart
                    metricChartView(
                        title: "Average Speed Comparison (km/h)",
                        metricKey: "avgSpeed",
                        color: .green
                    )
                    
                    // Elevation Chart
                    metricChartView(
                        title: "Elevation Gain Comparison (m)",
                        metricKey: "elevation",
                        color: .orange
                    )
                    
                    // Duration Chart
                    metricChartView(
                        title: "Duration Comparison (minutes)",
                        metricKey: "duration",
                        color: .red
                    )
                    
                    // Data Table
                    comparisonTable
                } else {
                    Text("Please select at least 2 rides to compare")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Ride Data Comparison")
    }
    
    // MARK: - Chart Components
    private func metricChartView(title: String, metricKey: String, color: Color) -> some View {
        let data = viewModel.getComparisonData()[metricKey] ?? []
        
        return VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .padding(.horizontal)
            
            if data.isEmpty {
                emptyChartView
            } else if !data.isEmpty && data.allSatisfy({ $0.value == 0 }) {
                zeroDataChartView(data: data)
            } else {
                normalChartView(data: data)
            }
        }
    }

    private var emptyChartView: some View {
        VStack {
            Text("No data available")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(height: 250)
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func zeroDataChartView(data: [RideDataPoint]) -> some View {
        let chartColors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .teal, .indigo, .mint]
        
        return VStack {
            Text("All values are zero")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(6)
                .background(Color(UIColor.systemBackground).opacity(0.8))
                .cornerRadius(4)
                .zIndex(1)
            
            Chart {
                ForEach(data.indices, id: \.self) { index in
                    let point = data[index]
                    BarMark(
                        x: .value("Date", point.shortFormattedDate),
                        y: .value("Value", 0)
                    )
                    .foregroundStyle(chartColors[index % chartColors.count].opacity(0.3))
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisValueLabel {
                        if let dateStr = value.as(String.self) {
                            Text(dateStr)
                                .font(.system(size: 8))
                                .rotationEffect(.degrees(-45))
                                .lineLimit(2)
                        }
                    }
                }
            }
            .chartYScale(domain: 0...1)
            .frame(height: 250)
            .padding()
        }
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func normalChartView(data: [RideDataPoint]) -> some View {
        let chartColors: [Color] = [.blue, .red, .green, .orange, .purple, .pink, .yellow, .teal, .indigo, .mint]
        let maxValue = data.map { $0.value }.max() ?? 1.0
        let yDomain = 0.0...max(maxValue, 1.0)
        
        return Chart {
            ForEach(data.indices, id: \.self) { index in
                let point = data[index]
                BarMark(
                    x: .value("Date", point.shortFormattedDate),
                    y: .value("Value", max(point.value, 0.1))
                )
                .foregroundStyle(chartColors[index % chartColors.count].gradient)
                .annotation(position: .top) {
                    Text(String(format: "%.1f", point.value))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisValueLabel {
                    if let dateStr = value.as(String.self) {
                        Text(dateStr)
                            .font(.system(size: 8))
                            .rotationEffect(.degrees(-45))
                            .lineLimit(2)
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .frame(height: 250)
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    // MARK: - Comparison Table
    private var comparisonTable: some View {
        let data = viewModel.getComparisonData()
        let sortedRides = viewModel.selectedRides.sorted(by: {
            ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast)
        })
        
        return VStack(alignment: .leading, spacing: 0) {
            Text("Detailed Comparison")
                .font(.headline)
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            ScrollView(.horizontal) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header
                    HStack(spacing: 0) {
                        Text("Metric")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .frame(width: 100, alignment: .leading)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color(UIColor.systemGray5))
                        
                        ForEach(sortedRides) { ride in
                            if let date = ride.createdAt {
                                VStack(spacing: 2) {
                                    Text(formatDate(date))
                                        .font(.caption)
                                        .fontWeight(.medium)
                                    Text(formatTime(date))
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .frame(width: 120, alignment: .center)
                                .padding(.vertical, 6)
                                .background(Color(UIColor.systemGray5))
                            }
                        }
                    }
                    
                    // Data Rows
                    tableRow(
                        title: "Distance (km)",
                        data: data["distance"] ?? [],
                        backgroundColor: Color(UIColor.systemBackground)
                    )
                    tableRow(
                        title: "Avg Speed (km/h)",
                        data: data["avgSpeed"] ?? [],
                        backgroundColor: Color(UIColor.systemGray6))
                    tableRow(
                        title: "Elevation (m)",
                        data: data["elevation"] ?? [],
                        backgroundColor: Color(UIColor.systemBackground))
                    tableRow(
                        title: "Duration (min)",
                        data: data["duration"] ?? [],
                        backgroundColor: Color(UIColor.systemGray6))
                }
            }
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(10)
            .padding(.horizontal)
        }
    }

    private func tableRow(title: String, data: [RideDataPoint], backgroundColor: Color) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.subheadline)
                .frame(width: 100, alignment: .leading)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(backgroundColor)
            
            ForEach(data) { point in
                Text(String(format: "%.1f", point.value))
                    .font(.subheadline)
                    .frame(width: 120, alignment: .center)
                    .padding(.vertical, 10)
                    .background(backgroundColor)
            }
        }
    }

    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
