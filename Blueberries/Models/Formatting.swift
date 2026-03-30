import Foundation

extension TimeInterval {
    var formattedAsTimer: String {
        let totalSeconds = Int(self)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return "\(mins):\(secs < 10 ? "0" : "")\(secs)"
    }
}
