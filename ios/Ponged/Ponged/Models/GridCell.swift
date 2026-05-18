import Foundation

struct GridCell: Hashable, Codable, Equatable {
    var col: Int
    var row: Int

    static func clamped(col: Int, row: Int) -> GridCell {
        GridCell(
            col: min(max(col, 0), MechanicConfig.shared.gridColumns - 1),
            row: min(max(row, 0), MechanicConfig.shared.gridRows - 1)
        )
    }

    var label: String { "\(col),\(row)" }
}
