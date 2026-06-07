import AVFoundation
import Foundation

struct CellSpatialPosition {
    var x: Float
    var y: Float
    var z: Float
    var gain: Float

    var point: AVAudio3DPoint { AVAudio3DPoint(x: x, y: y, z: z) }
}

enum SpatialTable {
    static func position(for cell: GridCell) -> CellSpatialPosition {
        position(
            for: cell,
            columns: MechanicConfig.shared.gridColumns,
            rows: MechanicConfig.shared.gridRows
        )
    }

    static func position(for cell: GridCell, columns: Int, rows: Int) -> CellSpatialPosition {
        position(interpolatedCol: Float(cell.col), interpolatedRow: Float(cell.row), columns: columns, rows: rows)
    }

    static func position(interpolatedCol: Float, interpolatedRow: Float) -> CellSpatialPosition {
        position(
            interpolatedCol: interpolatedCol,
            interpolatedRow: interpolatedRow,
            columns: MechanicConfig.shared.gridColumns,
            rows: MechanicConfig.shared.gridRows
        )
    }

    /// Display grid coords → direction on a fixed-radius sphere (constant loudness).
    /// (0,0) = 1 m in front; y +1 = overhead; y −1 = below.
    static func position(interpolatedCol: Float, interpolatedRow: Float, columns: Int, rows: Int) -> CellSpatialPosition {
        let cfg = MechanicConfig.shared
        let displayX = displayCoord(index: interpolatedCol, span: columns)
        let displayY = displayCoord(index: interpolatedRow, span: rows)

        let azimuth = displayX * cfg.maxAzimuthRadians
        let elevation = displayY * cfg.maxElevationRadians
        let r = cfg.spatialRadius
        let cosElev = cos(elevation)

        return CellSpatialPosition(
            x: r * cosElev * sin(azimuth),
            y: r * sin(elevation),
            z: -r * cosElev * cos(azimuth),
            gain: 1.0
        )
    }

    /// Grid index → display coord centered on 0 (e.g. 3-wide → −1, 0, 1).
    private static func displayCoord(index: Float, span: Int) -> Float {
        let center = Float(span - 1) / 2
        return index - center
    }

    static func interpolate(from: CellSpatialPosition, to: CellSpatialPosition, t: Float) -> CellSpatialPosition {
        CellSpatialPosition(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t,
            z: from.z + (to.z - from.z) * t,
            gain: from.gain + (to.gain - from.gain) * t
        )
    }

    static func travelLoopCount(from start: GridCell, to end: GridCell) -> Int {
        let base = MechanicConfig.shared.receiverMinLoops
        if start.row != end.row { return max(base, MechanicConfig.shared.verticalTravelMinLoops) }
        return base
    }

    static func waypoints(from start: GridCell, to end: GridCell, count: Int) -> [CellSpatialPosition] {
        guard count > 1 else { return [position(for: start)] }
        let startCol = Float(start.col)
        let startRow = Float(start.row)
        let endCol = Float(end.col)
        let endRow = Float(end.row)
        return (0..<count).map { i in
            let t = Float(i) / Float(count - 1)
            let col = startCol + (endCol - startCol) * t
            let row = startRow + (endRow - startRow) * t
            return position(interpolatedCol: col, interpolatedRow: row)
        }
    }
}
