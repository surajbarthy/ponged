import Foundation

enum CatchDetector {
  /// Target device attitude (degrees) for aiming at a grid cell.
  static func targetAttitude(for cell: GridCell) -> (pitch: Double, yaw: Double) {
    let cols = MechanicConfig.shared.gridColumns
    let rows = MechanicConfig.shared.gridRows
    let colNorm = cols > 1 ? Double(cell.col) / Double(cols - 1) : 0.5
    let rowNorm = rows > 1 ? Double(cell.row) / Double(rows - 1) : 0.5
    let yaw = (colNorm * 60) - 30
    let pitch = (rowNorm * 40) - 20
    return (pitch, yaw)
  }

  static func aimedCell(pitch: Double, yaw: Double) -> GridCell {
    ThrowMapper.cellFromAttitude(pitch: pitch, yaw: yaw)
  }

  static func isAligned(pitch: Double, yaw: Double, target: GridCell) -> Bool {
    let t = targetAttitude(for: target)
    let dPitch = abs(pitch - t.pitch)
    let dYaw = abs(yaw - t.yaw)
    let tol = MechanicConfig.shared.catchAngleTolerance
    return dPitch <= tol && dYaw <= tol
  }
}

@MainActor
final class CatchHoldTracker: ObservableObject {
  @Published private(set) var isHolding = false
  private var holdStart: Date?

  func update(pitch: Double, yaw: Double, target: GridCell) {
    if CatchDetector.isAligned(pitch: pitch, yaw: yaw, target: target) {
      if holdStart == nil { holdStart = Date() }
      if let start = holdStart,
         Date().timeIntervalSince(start) >= MechanicConfig.shared.catchHoldDuration {
        isHolding = true
      }
    } else {
      holdStart = nil
      isHolding = false
    }
  }

  func reset() {
    holdStart = nil
    isHolding = false
  }
}
