import Foundation

struct CellPanPosition {
    var pan: Float
    var gain: Float
}

enum PanTable {
    /// Maps 3×3 grid to stereo pan (-1…1) and gain (0…1).
    static func position(for cell: GridCell) -> CellPanPosition {
        let cols = MechanicConfig.shared.gridColumns
        let rows = MechanicConfig.shared.gridRows
        let colNorm = cols > 1 ? Float(cell.col) / Float(cols - 1) : 0.5
        let rowNorm = rows > 1 ? Float(cell.row) / Float(rows - 1) : 0.5
        let pan = (colNorm * 2) - 1
        let gain = 0.55 + (rowNorm * 0.45)
        return CellPanPosition(pan: pan, gain: gain)
    }

    /// Sender-far anchor (sound leaving sender toward receiver).
    static var senderFar: CellPanPosition {
        CellPanPosition(pan: -0.95, gain: 0.25)
    }

    static func interpolate(from: CellPanPosition, to: CellPanPosition, t: Float) -> CellPanPosition {
        CellPanPosition(
            pan: from.pan + (to.pan - from.pan) * t,
            gain: from.gain + (to.gain - from.gain) * t
        )
    }
}
