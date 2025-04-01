import CoreData

extension RideSummary {
    
    var safeDistance: Double {
        return distance > 0 ? distance : 0
    }
    
    var safeDuration: Double {
        return duration > 0 ? duration : 0
    }
    
    var safeElevationGain: Double {
        return elevationGain >= 0 ? elevationGain : 0
    }
    
    var safeAvgSpeed: Double {
        return avgSpeed > 0 ? avgSpeed : 0
    }

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
    }

    @discardableResult
    static func create(context: NSManagedObjectContext) -> RideSummary {
        RideSummary(context: context)
    }
    
    // 添加一个方法，安全地将 RideSummary 转换为普通结构体
    func toSummaryStruct() -> Summary {
        return Summary(
            duration: safeDuration,
            distance: safeDistance,
            avgSpeed: safeAvgSpeed,
            maxSpeed: maxSpeed > 0 ? maxSpeed : 0,
            elevationGain: safeElevationGain
        )
    }
}
