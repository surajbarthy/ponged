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

    /// Display coords: cols → -1,0,1 — rows → 0 (ear level), 1 (elevated).
    var label: String { displayLabel(columns: MechanicConfig.shared.gridColumns, rows: MechanicConfig.shared.gridRows) }

    /// Display label for an arbitrary grid size (e.g. 3×3 debug uses -1…1 on both axes).
    func displayLabel(columns: Int, rows: Int) -> String {
        let x = col - (columns - 1) / 2
        let y = row - (rows - 1) / 2
        return "\(x),\(y)"
    }

    /// Center cell (0,0) in display coordinates.
    static var center: GridCell { GridCell(col: 1, row: 0) }
}
