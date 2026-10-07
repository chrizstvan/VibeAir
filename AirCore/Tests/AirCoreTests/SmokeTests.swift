import Testing
import CH3

@Test func h3CompilesAndRuns() {
    // H3 versi C menerima RADIAN, bukan derajat
    var monas = LatLng(lat: degsToRads(-6.1754), lng: degsToRads(106.8272))
    var cell: H3Index = 0
    let err = latLngToCell(&monas, 7, &cell)
    #expect(err == 0)
    #expect(String(cell, radix: 16).hasPrefix("87"))
}