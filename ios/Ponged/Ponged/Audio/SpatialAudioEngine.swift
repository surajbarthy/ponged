import AVFoundation
import QuartzCore

@MainActor
final class SpatialAudioEngine: ObservableObject {
  private let engine = AVAudioEngine()
  private let player = AVAudioPlayerNode()
  private var buffers: [SoundPreset: AVAudioPCMBuffer] = [:]
  private var loopTimer: Timer?
  private var displayLink: CADisplayLink?
  private var travelStart: Date?
  private var travelPing: Ping?
  private var travelCompletion: (() -> Void)?
  private var currentPan = CellPanPosition(pan: 0, gain: 0.5)
  private var isTraveling = false

  init() {
    engine.attach(player)
    let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    engine.connect(player, to: engine.mainMixerNode, format: format)
    preloadBuffers(format: format)
    configureSession()
    try? engine.start()
  }

  private func configureSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
    try? session.setActive(true)
  }

  private func preloadBuffers(format: AVAudioFormat) {
    for preset in SoundPreset.allCases {
      buffers[preset] = SynthesizedSFX.makeBuffer(preset: preset, format: format)
    }
  }

  func stopAll() {
    loopTimer?.invalidate()
    loopTimer = nil
    stopTravel()
    player.stop()
  }

  func applyPan(_ position: CellPanPosition) {
    currentPan = position
    engine.mainMixerNode.pan = position.pan
    engine.mainMixerNode.outputVolume = position.gain
  }

  func playOnce(preset: SoundPreset, at cell: GridCell) {
    guard let buffer = buffers[preset] else { return }
    applyPan(PanTable.position(for: cell))
    if !player.isPlaying { player.play() }
    player.scheduleBuffer(buffer, at: nil, options: .interrupts) { }
  }

  func playPreviewLoops(preset: SoundPreset, at cell: GridCell, count: Int, completion: @escaping () -> Void) {
    var remaining = count
    let gap = MechanicConfig.shared.loopGap
    let duration = preset.approximateDuration

    func scheduleNext() {
      guard remaining > 0 else {
        completion()
        return
      }
      playOnce(preset: preset, at: cell)
      remaining -= 1
      if remaining > 0 {
        loopTimer?.invalidate()
        loopTimer = Timer.scheduledTimer(withTimeInterval: duration + gap, repeats: false) { _ in
          Task { @MainActor in scheduleNext() }
        }
      } else {
        loopTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { _ in
          Task { @MainActor in completion() }
        }
      }
    }
    scheduleNext()
  }

  func startTravel(ping: Ping, onComplete: @escaping () -> Void) {
    stopTravel()
    travelPing = ping
    travelCompletion = onComplete
    travelStart = Date()
    isTraveling = true

    let endPos = PanTable.position(for: ping.endCell)
    let config = MechanicConfig.shared
    let gap = config.loopGap
    let preset = ping.preset

    func scheduleLoop() {
      guard isTraveling else { return }
      playOnce(preset: preset, at: ping.endCell)
      loopTimer?.invalidate()
      loopTimer = Timer.scheduledTimer(withTimeInterval: preset.approximateDuration + gap, repeats: false) { _ in
        Task { @MainActor in
          if self.isTraveling { scheduleLoop() }
        }
      }
    }
    scheduleLoop()

    let link = CADisplayLink(target: DisplayLinkProxy { [weak self] in
      Task { @MainActor in self?.tickTravel(endPos: endPos) }
    }, selector: #selector(DisplayLinkProxy.tick))
    link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
    link.add(to: .main, forMode: .common)
    displayLink = link
  }

  private func tickTravel(endPos: CellPanPosition) {
    guard let start = travelStart else { return }
    let config = MechanicConfig.shared
    let elapsed = Date().timeIntervalSince(start)
    let rawT = elapsed / config.travelDuration
    let t = config.easedProgress(rawT)
    let progress = Float(min(max(t, 0), 1))

    let distanceRatio = Float(min(elapsed * config.travelSpeed / config.imaginaryDistance, 1))
    var pos = PanTable.interpolate(from: PanTable.senderFar, to: endPos, t: progress)
    pos.gain *= (0.35 + 0.65 * distanceRatio)

    applyPan(pos)

    if rawT >= 1 {
      stopTravelLink()
      applyPan(endPos)
      travelCompletion?()
      travelCompletion = nil
    }
  }

  private func stopTravel() {
    isTraveling = false
    stopTravelLink()
    loopTimer?.invalidate()
    loopTimer = nil
    travelStart = nil
    travelPing = nil
  }

  private func stopTravelLink() {
    displayLink?.invalidate()
    displayLink = nil
  }
}

private final class DisplayLinkProxy: NSObject {
  private let handler: () -> Void
  init(handler: @escaping () -> Void) { self.handler = handler }
  @objc func tick() { handler() }
}

enum SynthesizedSFX {
  static func makeBuffer(preset: SoundPreset, format: AVAudioFormat) -> AVAudioPCMBuffer? {
    let sampleRate = format.sampleRate
    let duration = preset.approximateDuration
    let frameCount = AVAudioFrameCount(sampleRate * duration)
    guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
    buffer.frameLength = frameCount

    let freq = preset.baseFrequency
  let channelCount = Int(format.channelCount)
    guard let channels = buffer.floatChannelData else { return nil }

    for frame in 0..<Int(frameCount) {
      let t = Double(frame) / sampleRate
      let envelope = exp(-t * 8)
      let sample = Float(sin(2 * .pi * freq * t) * envelope * 0.55)
      for ch in 0..<channelCount {
        channels[ch][frame] = sample
      }
    }
    return buffer
  }
}
