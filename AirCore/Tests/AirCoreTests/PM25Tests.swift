import Testing
import AirCore

@Test func aquConvertsLikeNotebook() {
    #expect(abs(PM25.concentration(fromAQI: 95)! - 33.02) < 0.01)
    #expect(PM25.concentration(fromAQI: 0) == 0)
    #expect(PM25.concentration(fromAQI: 50) == 12.0)
    #expect(PM25.concentration(fromAQI: 151) == 55.5)
}

@Test func aqiOutsideScaleIsNil() {
    #expect(PM25.concentration(fromAQI: -1) == nil)
    #expect(PM25.concentration(fromAQI: 600) == nil)
}

@Test func categoryEdges() {
    #expect(PM25.category(forConcentration: 12.0) == .good)
    #expect(PM25.category(forConcentration: 12.1) == .moderate)
    #expect(PM25.category(forConcentration: 35.49) == .moderate)
    #expect(PM25.category(forConcentration: 35.5) == .sensitive)
    #expect(PM25.category(forConcentration: 300) == .hazardous)
}