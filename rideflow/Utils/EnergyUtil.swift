import Foundation

struct EnergyUtil {
    // 估算功率（瓦特）
    static func estimatePower(weight: Double, speed: Double) -> Double {
        // 简化的功率估算公式
        // P = (体重 * 9.8 * 速度 * 0.01) + (0.5 * 1.225 * 0.5 * 速度^3)
        // 其中：
        // - 9.8 是重力加速度
        // - 0.01 是滚动阻力系数
        // - 1.225 是空气密度
        // - 0.5 是假设的迎风面积
        
        let rollingResistance = weight * 9.8 * speed * 0.01
        let airResistance = 0.5 * 1.225 * 0.5 * pow(speed, 3)
        
        return rollingResistance + airResistance
    }
    
    // 计算卡路里消耗
    static func calories(power: Double, duration: TimeInterval) -> Double {
        // 1瓦特 = 0.86千卡/小时
        // 卡路里 = 功率 * 0.86 * 时间(小时)
        return power * 0.86 * (duration / 3600)
    }
}
