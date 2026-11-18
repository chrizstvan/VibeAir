import Testing
import AirCore

@Test func aquConvertsLikeNotebook() {
    #expect(abs(PM25.concentration(fromAQI: 95)! - 33.02) < 0.01)
    #expect(PM25.concentration(fromAQI: 0) == 0)
    #expect(PM25.concentration(fromAQI: 50) == 12.0)
    #expect(PM25.concentration(fromAQI: 151) == 55.5)
}