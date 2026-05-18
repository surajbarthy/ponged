import Foundation

enum ThrowMapper {
  private static let cols = MechanicConfig.shared.gridColumns
  private static let rows = MechanicConfig.shared.gridRows

  static func cellFromAttitude(pitch: Double, yaw: Double) -> GridCell {
    let col = Int(round((yaw + 45) / 90 * Double(cols - 1)))
    let row = Int(round((pitch + 45) / 90 * Double(rows - 1)))
    return GridCell.clamped(col: col, row: row)
  }

  static func computeEndCell(start: GridCell, vector: ThrowVector) -> GridCell {
    let direction = directionBucket(yaw: vector.yaw)
    var end = neighborSteps(from: start, direction: direction, steps: MechanicConfig.shared.neighborStepCount)
    if end == start {
      end = nudgeDifferent(from: start)
    }
    return end
  }

  static func computeEndCell(start: GridCell, tapEnd: GridCell) -> GridCell {
    let end = GridCell.clamped(col: tapEnd.col, row: tapEnd.row)
    return end == start ? nudgeDifferent(from: start) : end
  }

  private enum Direction: CaseIterable {
    case n, ne, e, se, s, sw, w, nw
  }

  private static func directionBucket(yaw: Double) -> Direction {
    let normalized = (yaw.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360)
    let index = Int((normalized + 22.5) / 45.0) % 8
    return Direction.allCases[index]
  }

  private static func neighborSteps(from: GridCell, direction: Direction, steps: Int) -> GridCell {
    var cell = from
    for _ in 0..<steps {
      var dc = 0
      var dr = 0
      switch direction {
      case .n: dr = 1
      case .ne: dc = 1; dr = 1
      case .e: dc = 1
      case .se: dc = 1; dr = -1
      case .s: dr = -1
      case .sw: dc = -1; dr = -1
      case .w: dc = -1
      case .nw: dc = -1; dr = 1
      }
      cell = GridCell.clamped(col: cell.col + dc, row: cell.row + dr)
    }
    return cell
  }

  private static func nudgeDifferent(from: GridCell) -> GridCell {
    if from.col < cols - 1 { return GridCell(col: from.col + 1, row: from.row) }
    if from.row < rows - 1 { return GridCell(col: from.col, row: from.row + 1) }
    if from.col > 0 { return GridCell(col: from.col - 1, row: from.row) }
    return GridCell(col: from.col, row: max(from.row - 1, 0))
  }
}
