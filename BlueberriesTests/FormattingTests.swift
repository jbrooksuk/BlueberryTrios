import Testing
@testable import Blueberries

@Suite("Formatting")
struct FormattingTests {
    @Test("Formats zero seconds")
    func zeroSeconds() {
        #expect(TimeInterval(0).formattedAsTimer == "0:00")
    }

    @Test("Formats seconds with zero padding")
    func singleDigitSeconds() {
        #expect(TimeInterval(5).formattedAsTimer == "0:05")
        #expect(TimeInterval(9).formattedAsTimer == "0:09")
    }

    @Test("Formats double digit seconds")
    func doubleDigitSeconds() {
        #expect(TimeInterval(10).formattedAsTimer == "0:10")
        #expect(TimeInterval(59).formattedAsTimer == "0:59")
    }

    @Test("Formats minutes")
    func minutes() {
        #expect(TimeInterval(60).formattedAsTimer == "1:00")
        #expect(TimeInterval(61).formattedAsTimer == "1:01")
        #expect(TimeInterval(90).formattedAsTimer == "1:30")
    }

    @Test("Formats large values")
    func largeValues() {
        #expect(TimeInterval(3600).formattedAsTimer == "60:00")
        #expect(TimeInterval(3661).formattedAsTimer == "61:01")
    }
}
