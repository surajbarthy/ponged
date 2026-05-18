import Foundation

enum TravelCurve: String {
    case linear
    case easeInOut
}

struct MechanicConfig {
    static let shared = MechanicConfig()

    let loopGap: TimeInterval = 0.5
    let travelDuration: TimeInterval = 10
    let imaginaryDistance: Double = 50
    var travelSpeed: Double { imaginaryDistance / travelDuration }
    let gridColumns: Int = 3
    let gridRows: Int = 3
    let catchHoldDuration: TimeInterval = 0.3
    let catchAngleTolerance: Double = 15
    let senderPreviewLoops: Int = 3
    let travelCurve: TravelCurve = .linear
    let minReceiverOpenDelay: TimeInterval = 0
    let neighborStepCount: Int = 2

    func easedProgress(_ t: Double) -> Double {
        let clamped = min(max(t, 0), 1)
        switch travelCurve {
        case .linear:
            return clamped
        case .easeInOut:
            return clamped * clamped * (3 - 2 * clamped)
        }
    }
}
