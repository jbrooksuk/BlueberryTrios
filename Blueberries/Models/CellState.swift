import Foundation

enum CellState: String, Codable {
    case undecided = "_"
    case empty = "x"
    case berry = "o"

    var next: CellState {
        switch self {
        case .undecided: return .empty
        case .empty: return .berry
        case .berry: return .undecided
        }
    }
}
