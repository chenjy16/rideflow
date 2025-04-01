import CoreData
import CoreLocation

extension Ride {

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        createdAt = Date()
        updatedAt = Date()
    }

    static var sortDescriptors: [NSSortDescriptor] {
        [NSSortDescriptor(keyPath: \Ride.createdAt, ascending: false)]
    }

    @discardableResult
    static func create(name: String, context: NSManagedObjectContext) -> Ride {
        Ride(context: context).apply {
            $0.name = name
        }
    }

    func asRideSummary() -> Summary {
        Summary(
            duration: summary?.duration ?? 0,
            distance: summary?.distance ?? 0,
            avgSpeed: summary?.avgSpeed ?? 0,
            maxSpeed: summary?.maxSpeed ?? 0,
            elevationGain: summary?.elevationGain ?? 0
        )
    }

    func locations() -> [CLLocation] {
        track?.locations() ?? []
    }
}
