import Combine
import Foundation

class Timer2 {

    let timer = Timer.TimerPublisher(interval: 1.0, runLoop: .main, mode: .default)
    private var cancellable = Set<AnyCancellable>()
    
    // 添加 publisher 属性
     var publisher: Timer.TimerPublisher {
         return timer
     }

    init() {
        timer
            .connect()
            .store(in: &cancellable)
    }

    deinit {
        cancellable.forEach { $0.cancel() }
    }
}
