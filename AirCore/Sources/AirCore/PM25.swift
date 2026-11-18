public enum AirCategory: Int, Sendable, CaseIterable, Comparable {
    case good, moderate, sensitive, unhealthy, veryUnhealthy, hazardous

    public static func < (lhs: AirCategory, rhs: AirCategory) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

public enum PM25 {
    struct Breakpoint {
        let aqiLow, aqiHigh: Double
        let concentrationLow, concentrationHigh: Double
    }

    // AQI US EPA Table old version (same with notebook)
    static let usLegacy: [Breakpoint] = [
        Breakpoint(aqiLow: 0, aqiHigh: 50, concentrationLow: 0.0, concentrationHigh: 12.0),
        Breakpoint(aqiLow: 51, aqiHigh: 100, concentrationLow: 12.1, concentrationHigh: 35.4),
        Breakpoint(aqiLow: 101, aqiHigh: 150, concentrationLow: 35.5, concentrationHigh: 55.4),
        Breakpoint(aqiLow: 151, aqiHigh: 200, concentrationLow: 55.5, concentrationHigh: 150.4),
        Breakpoint(aqiLow: 201, aqiHigh: 300, concentrationLow: 150.5, concentrationHigh: 250.4),
        Breakpoint(aqiLow: 301, aqiHigh: 400, concentrationLow: 250.5, concentrationHigh: 350.4),
        Breakpoint(aqiLow: 401, aqiHigh: 500, concentrationLow: 350.5, concentrationHigh: 500.4),
    ]

    /// AQI (US scale) to µg/m³. Nil if not in 0 to 500.
    public static func concentration(fromAQI aqi: Double) -> Double? {
        guard aqi >= 0 else { return nil }
        for bp in usLegacy where aqi <= bp.aqiHigh {
            return bp.concentrationLow + (aqi - bp.aqiLow) * (bp.concentrationHigh - bp.concentrationLow) / (bp.aqiHigh - bp.aqiLow)
        }
        return nil
    }

    /// category from concentration µg/m³.
    public static func category(forConcentration value: Double) -> AirCategory {
        switch value {
            case ..<12.1: return .good
            case ..<35.5: return .moderate
            case ..<55.5: return .sensitive
            case ..<150.5: return .unhealthy
            case ..<250.5: return .veryUnhealthy
            default: return .hazardous
        }
    }
}
