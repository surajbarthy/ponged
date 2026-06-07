import SwiftUI

struct ThrowView: View {
  @Bindable var session: GameSession
  let preset: SoundPreset
  @EnvironmentObject private var audio: SpatialAudioEngine
  @StateObject private var motion = MotionManager()

  @State private var phase: ThrowPhase = .pickStart
  @State private var startCell: GridCell?
  @State private var endCell: GridCell?
  @State private var isPreviewing = false

  var onDone: (Ping) -> Void

  enum ThrowPhase {
    case pickStart
    case pickEnd
    case ready
  }

  var body: some View {
    ZStack {
      Color(red: 0.95, green: 0.85, blue: 1).ignoresSafeArea()
      VStack(spacing: 16) {
        Text(preset.displayName)
          .font(.largeTitle.bold())
        Text(instruction)
          .font(.subheadline)
          .multilineTextAlignment(.center)
          .padding(.horizontal)

        Grid3x3View(
          startCell: startCell,
          endCell: endCell,
          onCellTap: session.useGyroThrow ? nil : handleTap
        )

        Toggle("Gyro throw (V1b)", isOn: $session.useGyroThrow)
          .padding(.horizontal)

        if session.useGyroThrow {
          Button("Throw!") { performGyroThrow() }
            .buttonStyle(.borderedProminent)
            .disabled(isPreviewing)
        } else if phase == .ready {
          Button("Send ping") { commitThrow() }
            .buttonStyle(.borderedProminent)
            .disabled(isPreviewing)
        }
      }
    }
    .onAppear { motion.startUpdates() }
    .onDisappear { motion.stopUpdates() }
  }

  private var instruction: String {
    if session.useGyroThrow {
      return "Grip phone, mimic a throw, tap Throw!"
    }
    switch phase {
    case .pickStart: return "Tap START cell"
    case .pickEnd: return "Tap END cell"
    case .ready: return "Ready to send"
    }
  }

  private func handleTap(_ cell: GridCell) {
    switch phase {
    case .pickStart:
      startCell = cell
      phase = .pickEnd
    case .pickEnd:
      guard let start = startCell else { return }
      endCell = ThrowMapper.computeEndCell(start: start, tapEnd: cell)
      phase = .ready
    case .ready:
      break
    }
  }

  private func performGyroThrow() {
    guard !isPreviewing else { return }
    let vector = motion.snapshotVector()
    let start = ThrowMapper.cellFromAttitude(pitch: vector.pitch, yaw: vector.yaw)
    let end = ThrowMapper.computeEndCell(start: start, vector: vector)
    startCell = start
    endCell = end
    commitThrow(vector: vector)
  }

  private func commitThrow(vector: ThrowVector? = nil) {
    guard let start = startCell, let end = endCell, !isPreviewing else { return }
    isPreviewing = true
    let v = vector ?? motion.snapshotVector()
    audio.playPreviewLoops(preset: preset, at: start, count: MechanicConfig.shared.senderPreviewLoops) {
      let ping = session.makePing(preset: preset, start: start, end: end, vector: v)
      isPreviewing = false
      onDone(ping)
    }
  }
}
