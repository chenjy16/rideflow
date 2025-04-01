

import Combine
import Injected
import Foundation

class ViewModel {
    @Injected var rideService: RideService
    @Injected var locationService: LocationService


    var cancellable = Set<AnyCancellable>()
    
    
    
    
    
}
