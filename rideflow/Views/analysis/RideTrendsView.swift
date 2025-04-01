import SwiftUI
import Charts

struct RideTrendsView: View {
    @StateObject private var viewModel = RideTrendsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 标题
                HStack {
                    Text("Cycling Trends")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    // 移除时间范围选择器，因为只使用周视图
                }
                .padding(.horizontal)
                
                // 距离图表
                metricChartView(
                    title: "Distance",
                    metric: .distance,
                    color: .blue,
                    icon: "figure.walk"
                )
                
                // 速度图表
                metricChartView(
                    title: "Speed",
                    metric: .speed,
                    color: .green,
                    icon: "speedometer"
                )
                
                // 时间图表
                metricChartView(
                    title: "Duration",
                    metric: .duration,
                    color: .orange,
                    icon: "clock"
                )
                
                // 爬升图表
                metricChartView(
                    title: "Elevation",
                    metric: .elevation,
                    color: .red,
                    icon: "mountain.2"
                )
                
            }
            .padding(.vertical)
        }
        .onAppear {
            // 确保初始化时加载数据
            viewModel.loadData()
        }
    }
    
    // 单个指标图表视图
    private func metricChartView(title: String, metric: TrendMetric, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {  // 减小间距使布局更紧凑
            // 图表标题
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(metric.localizedTitle)
                    .font(.headline)
                
                Spacer()
                
            }
            .padding(.horizontal, 12)  // 减小水平内边距
            
            // 图表
            chartView(for: metric, color: color)
                .frame(height: 180)  // 稍微减小高度使整体更紧凑
                .padding(.vertical, 8)  // 减小垂直内边距
                .padding(.horizontal, 8)  // 减小水平内边距
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 12)  // 减小外部水平内边距
        }
    }
    
    // 图表视图 - 使用子视图替换复杂的内联代码
    private func chartView(for metric: TrendMetric, color: Color) -> some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.dailySummaries.isEmpty {
                Text("No riding data")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 使用单独的结构体处理图表内容
                ChartContentView(
                    metric: metric,
                    color: color,
                    viewModel: viewModel
                )
            }
        }
    }
    
    // 统计卡片视图
    private func statCard(title: String, value: Double, unit: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(String(format: "%.1f", value)) \(unit)")
                    .font(.headline)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// 将复杂的图表内容提取到单独的结构体中
private struct ChartContentView: View {
    let metric: TrendMetric
    let color: Color
    let viewModel: RideTrendsViewModel
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .top, spacing: 0) {
                // Y轴标签（包含单位）
                Text("\(metric.localizedTitle) (\(metric.unitLabel))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .frame(width: 16, height: 120)
                    .padding(.top, 20)
                
                VStack(spacing: 0) {
                    // 图表主体
                    chartMainView
                    
                    // X轴标签 - 显示"本周日期"
                    HStack {
                        Spacer()
                        Text("This Week's Dates")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 2)
                }
            }
        }
    }
    
    // 图表主体视图 - 修改 chartXAxis 部分
    private var chartMainView: some View {
            Chart {
                ForEach(viewModel.dailySummaries) { summary in
                    LineMark(
                        x: .value("Date", summary.formattedDate()),
                        y: .value(metric.localizedTitle, metricValue(for: summary))
                    )
                    .foregroundStyle(color)
                    .interpolationMethod(.catmullRom)
                    
                    PointMark(
                        x: .value("Date", summary.formattedDate()),
                        y: .value(metric.localizedTitle, metricValue(for: summary))
                    )
                    .foregroundStyle(color)
                    .symbolSize(50) // 增大点的大小，使其更容易看见
                }
            }
            // 关键修改：明确设置Y轴域范围，确保数据可见
            .chartYScale(domain: yAxisDomainFromZero())
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let doubleValue = value.as(Double.self) {
                            // 根据不同指标使用不同的格式化方式
                            Text(String(format: "%.2f", doubleValue))
                            .font(.caption2)
                            .padding(.trailing, 4) // 添加右侧内边距，避免数值被截断
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let dateString = value.as(String.self) {
                            // 修改这里：只显示日期数字部分
                            let components = dateString.split(separator: "-")
                            if components.count >= 3, let day = Int(components[2]) {
                                Text("\(day)")
                                    .font(.caption2)
                            } else {
                                Text(dateString)
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
            .frame(height: 180)
        // 关键修改：增加图表的内边距，特别是顶部和左侧
            .padding(.leading, 20)
            .padding(.trailing, 8)
            .padding(.top, 16) // 增加顶部内边距
            .padding(.bottom, 8) // 增加底部内边距
    }
        
    // 修改指标值获取方法，确保返回合理的数值
    private func metricValue(for summary: DailyRideSummary) -> Double {
        switch metric {
        case .distance:
            return max(summary.distance, 0.01) // 确保至少有一个最小值
        case .speed:
            return max(summary.avgSpeed, 0.01)
        case .duration:
            // 如果时间太短，转换为小时后可能接近0，这里确保有最小值
            let hours = summary.duration / 3600
            return max(hours, 0.01)
        case .elevation:
            return max(summary.elevationGain, 0.01)
        }
    }
        
        // 修改Y轴域范围计算方法，确保显示合理的范围
    private func yAxisDomainFromZero() -> ClosedRange<Double> {
        let values = viewModel.dailySummaries.map { metricValue(for: $0) }
        guard !values.isEmpty else { return 0...1 }
        
        // 始终从0开始
        let minValue = 0.0
        // 找出最大值，如果最大值太小，则使用默认值
        let maxValue = values.max() ?? 1
        
        // 为不同指标设置不同的最小显示范围
        let minDisplayValue: Double
        switch metric {
        case .elevation:
            // 爬升高度使用米为单位，设置更合适的最小显示值
            minDisplayValue = 10 // 至少显示10米的范围
        default:
            minDisplayValue = 0.1
        }
        
        // 如果最大值太小，使用一个合理的默认范围
        if maxValue < minDisplayValue {
            return 0...minDisplayValue
        }
        
        // 添加顶部空间，确保数据点不会贴着顶部
        let padding = maxValue * 0.3
        let upperBound = maxValue + padding
        
        return minValue...upperBound
    }
    
    // 定义日期标签结构
    private struct DateLabel {
        let date: Date
        let label: String      // 完整标签，用于数据匹配
        let shortLabel: String // 简短标签，用于显示
    }
    
    // 获取当前周的七天日期
    private func getWeekDays() -> [DateLabel] {
        let calendar = Calendar.current
        let today = Date()
        
        // 获取本周的周一日期
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let firstDayOfWeek = calendar.date(from: components) else {
            return []
        }
        
        // 生成周一到周日的日期标签
        var weekDays: [DateLabel] = []
        let fullFormatter = DateFormatter()
        fullFormatter.dateFormat = "yyyy-MM-dd" // 用于数据匹配的完整格式
        
        let shortFormatter = DateFormatter()
        shortFormatter.dateFormat = "d" // 简短格式，只显示日期数字
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: firstDayOfWeek) {
                weekDays.append(DateLabel(
                    date: date,
                    label: fullFormatter.string(from: date),
                    shortLabel: shortFormatter.string(from: date) // 只显示日期数字
                ))
            }
        }
        
        return weekDays
    }
    
  
}
