import SwiftUI

struct ReceiveView: View {
  let ping: Ping
  @Bindable var session: GameSession
  var onCaught: () -> Void

  @StateObject private var motion = MotionManager()
  @StateObject private var audio = SpatialAudioEngine()
  @StateObject private var catchTracker = CatchHoldTracker()

  @State private var travelArrived = false
  @State private var catchWindowOpen = false

  var body: some View {
    ZStack {
      Color(red: 0.85, green: 0.9, blue: 1).ignoresSafeArea()
      VStack(spacing: 16) {
        Text("Catch it!")
          .font(.title.bold())
        Text(travelArrived ? "Align your phone to the green cell" : "Listen… it's approaching")
          .font(.subheadline)

        Grid3x3View(
          endCell: ping.endCell,
          dimEndUntilArrival: true,
          travelArrived: travelArrived,
          pulseEndCell: catchWindowOpen,
          onCellTap: { cell in
            if cell == ping.endCell && catchWindowOpen {
              session.debugTapCatchCount += 1
              print("[Ponged] debug tap catch count=\(session.debugTapCatchCount)")
              finishCatch()
            }
          }
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
    .onChange(of: motion.pitch) { _, _ in evaluateCatch() }
    .onChange(of: motion.yaw) { _, _ in evaluateCatch() }
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
      }
    }
  }

  private func evaluateCatch() {
    guard catchWindowOpen else { return }
    catchTracker.update(pitch: motion.pitch, yaw: motion.yaw, target: ping.endCell)
  }

  private func finishCatch() {
    audio.stopAll()
    session.markCaught()
    onCaught()
  }
}
