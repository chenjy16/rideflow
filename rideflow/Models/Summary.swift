import Foundation
import CoreLocation

struct Summary {
    let duration: TimeInterval // s
    let distance: CLLocationDistance // m
    let avgSpeed: CLLocationSpeed // m/s
    let maxSpeed: CLLocationSpeed // ms
    let elevationGain: CLLocationDistance // m
    let avgPower: Double
    let energy: Double
    let weigthLoss: Double

    init(duration: Double, distance: CLLocationDistance,
         avgSpeed: CLLocationSpeed, maxSpeed: CLLocationSpeed,
         elevationGain: CLLocationDistance) {

        // 过滤负值
        self.duration = max(.zero, duration)
        self.distance = max(.zero, distance)
        self.avgSpeed = max(.zero, avgSpeed)
        self.maxSpeed = max(.zero, maxSpeed)
        self.elevationGain = max(.zero, elevationGain)

        // 计算
        let configuration = Parameters(avgSpeed: Measurement(value: avgSpeed, unit: .metersPerSecond))
        let power = Power.power(parameters: configuration)
        self.avgPower = power.value
        let energy = Energy.energy(power: power, duration: Measurement(value: duration, unit: .seconds))
        self.energy = energy.value
        self.weigthLoss = Weight.loss(energy: energy).value
    }

    static func empty() -> Self {
        .init(duration: 0, distance: 0, avgSpeed: 0, maxSpeed: 0, elevationGain: 0)
    }
}
