import Foundation

// Carbon Emission Calculation Tool
struct CarbonEmission {
    // Calculate saved carbon emissions (grams)
    static func calculateSavedEmission(distance: Double) -> Double {
        // Assume an average car emits 120g of CO₂ per kilometer
        return distance * 120
    }
    
    // Convert carbon emissions into an environmental benefit description
    static func emissionToEnvironmentalBenefit(emission: Double) -> String {
        if emission < 1000 {
            // Less than 1 kg, display in grams
            return "Equivalent to saving \(Int(emission))g of CO₂ emissions"
        } else if emission < 10000 {
            // 1-10 kg
            return String(format: "Equivalent to saving %.2f kg of CO₂ emissions", emission / 1000.0)
        } else {
            // More than 10 kg, convert to tree absorption equivalent
            let trees = emission / 7000 // Assume one tree absorbs 7 kg of CO₂ per year
            return String(format: "Equivalent to the annual CO₂ absorption of %.1f trees", trees)
        }
    }
}
