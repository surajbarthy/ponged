import SwiftUI

struct ReceiveView: View {
  let ping: Ping
  @Bindable var session: GameSession
  var onCaught: () -> Void

  @EnvironmentObject private var audio: SpatialAudioEngine
  @StateObject private var motion = MotionManager()
  @StateObject private var catchTracker = CatchHoldTracker()

  @State private var travelArrived = false
  @State private var catchWindowOpen = false
  @State private var aimedCell: GridCell?

  var body: some View {
    ZStack {
      Color(red: 0.85, green: 0.9, blue: 1).ignoresSafeArea()
      VStack(spacing: 16) {
        Text("Catch it!")
          .font(.title.bold())
        Text(travelArrived ? "Align your phone to the green cell" : "Listen… it's approaching")
          .font(.subheadline)
        if !travelArrived {
          Text("Headphones + HRTF — listen for height change")
            .font(.caption)
            .foregroundStyle(.secondary)
        } else {
          Text("Tap a cell to preview · aim at green to catch")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Grid3x3View(
          startCell: ping.startCell,
          endCell: ping.endCell,
          highlightCell: aimedCell,
          pulseEndCell: catchWindowOpen,
          dimEndUntilArrival: true,
          travelArrived: travelArrived,
          onCellTap: catchWindowOpen ? handleCellTap : nil
        )

        if catchTracker.isHolding {
          Text("Hold steady…")
            .foregroundStyle(.green)
        }
      }
    }
    .onAppear {
      motion.startUpdates()
      startReceiveSequence()
    }
    .onDisappear {
      motion.stopUpdates()
      audio.stopAll()
    }
    .onChange(of: motion.pitch) { _, _ in updateMotion() }
    .onChange(of: motion.yaw) { _, _ in updateMotion() }
    .onChange(of: catchTracker.isHolding) { _, holding in
      if holding { finishCatch() }
    }
  }

  private func startReceiveSequence() {
    let delay = MechanicConfig.shared.minReceiverOpenDelay
    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
      audio.startTravel(ping: ping) {
        travelArrived = true
        catchWindowOpen = true
        catchTracker.reset()
        updateMotion()
      }
    }
  }

  private func handleCellTap(_ cell: GridCell) {
    audio.playOnce(preset: ping.preset, at: cell)
    if cell == ping.endCell {
      session.debugTapCatchCount += 1
      print("[Ponged] debug tap catch count=\(session.debugTapCatchCount)")
      finishCatch()
    }
  }

  private func updateMotion() {
    guard catchWindowOpen else { return }
    aimedCell = CatchDetector.aimedCell(pitch: motion.pitch, yaw: motion.yaw)
    catchTracker.update(pitch: motion.pitch, yaw: motion.yaw, target: ping.endCell)
  }

  private func finishCatch() {
    audio.stopAll()
    session.markCaught()
    onCaught()
  }
}
