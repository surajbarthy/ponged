import AVFoundation
import Combine

enum SpatialOutputMode: String, CaseIterable {
  case hrtf = "HRTF"
  case stereoPan = "Stereo Pan"
}

@MainActor
final class SpatialAudioEngine: ObservableObject {
  private let engine = AVAudioEngine()
  private let environment = AVAudioEnvironmentNode()
  private let playerMixer = AVAudioMixerNode()
  private let player = AVAudioPlayerNode()
  private var monoBuffers: [SoundPreset: AVAudioPCMBuffer] = [:]
  private var durations: [SoundPreset: TimeInterval] = [:]
  private var loopTimer: Timer?
  private var travelCompletion: (() -> Void)?
  private var travelWaypoints: [CellSpatialPosition] = []
  private var travelLoopsPlayed = 0
  private var currentSpatial = CellSpatialPosition(x: 0, y: 0, z: -1, gain: 1)
  private var isTraveling = false

  @Published private(set) var debugPositionLabel: String = "—"
  @Published private(set) var engineRunning = false
  @Published var outputMode: SpatialOutputMode = .hrtf {
    didSet { if oldValue != outputMode { rebuildGraph() } }
  }
  @Published private(set) var loadedPresetCount: Int = 0

  init() {
    engine.attach(player)
    engine.attach(environment)
    engine.attach(playerMixer)
    engine.mainMixerNode.outputVolume = 1

    preloadFiles()
    configureSession()
    rebuildGraph()
  }

  private func configureSession() {
    let session = AVAudioSession.sharedInstance()
    try? session.setCategory(
      .playback,
      mode: .default,
      options: [.mixWithOthers, .allowBluetoothA2DP]
    )
    try? session.setActive(true)
  }

  private func rebuildGraph() {
    if engine.isRunning { engine.stop() }

    engine.disconnectNodeOutput(player)
    engine.disconnectNodeInput(environment)
    engine.disconnectNodeOutput(environment)
    engine.disconnectNodeInput(playerMixer)
    engine.disconnectNodeOutput(playerMixer)

    switch outputMode {
    case .hrtf:
      environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
      environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)
      let attenuation = environment.distanceAttenuationParameters
      attenuation.referenceDistance = 100
      attenuation.maximumDistance = 10_000
      attenuation.rolloffFactor = 0.01
      player.sourceMode = .pointSource
      player.renderingAlgorithm = .HRTFHQ
      player.pointSourceInHeadMode = .bypass
      player.reverbBlend = 0
      player.volume = 1
      let monoFormat = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)
      engine.connect(player, to: environment, format: monoFormat)
      engine.connect(environment, to: engine.mainMixerNode, format: nil)
      print("[Ponged] Graph: player(mono) → environment(HRTF) → mainMixer")

    case .stereoPan:
      player.renderingAlgorithm = .equalPowerPanning
      engine.connect(player, to: playerMixer, format: nil)
      engine.connect(playerMixer, to: engine.mainMixerNode, format: nil)
      print("[Ponged] Graph: player → mixer → mainMixer")
    }

    startEngine()
  }

  private func startEngine() {
    engine.prepare()
    do {
      try engine.start()
      engineRunning = true
      print("[Ponged] Engine started (\(outputMode.rawValue))")
    } catch {
      engineRunning = false
      print("[Ponged] Engine start failed: \(error)")
    }
  }

  private func preloadFiles() {
    for preset in SoundPreset.allCases {
      guard let url = Bundle.main.url(forResource: preset.resourceName, withExtension: preset.resourceExtension) else {
        print("[Ponged] Missing: \(preset.resourceName).\(preset.resourceExtension)")
        continue
      }
      guard let file = try? AVAudioFile(forReading: url) else {
        print("[Ponged] Cannot read: \(preset.resourceName)")
        continue
      }
      guard let mono = makeMonoBuffer(from: file) else {
        print("[Ponged] Cannot downmix: \(preset.resourceName)")
        continue
      }
      monoBuffers[preset] = mono
      durations[preset] = Double(mono.frameLength) / mono.format.sampleRate
      print(
        "[Ponged] Loaded \(preset.resourceName) \(String(format: "%.2f", durations[preset]!))s"
          + " src=\(file.fileFormat.channelCount)ch → mono"
      )
    }
    loadedPresetCount = monoBuffers.count
  }

  /// HRTF only spatializes mono. Bundled MP3s are stereo — downmix before playback.
  private func makeMonoBuffer(from file: AVAudioFile) -> AVAudioPCMBuffer? {
    let srcFormat = file.processingFormat
    file.framePosition = 0
    let frameCount = AVAudioFrameCount(file.length)
    guard
      let srcBuffer = AVAudioPCMBuffer(pcmFormat: srcFormat, frameCapacity: frameCount)
    else { return nil }

    do {
      try file.read(into: srcBuffer)
    } catch {
      print("[Ponged] Read failed: \(error)")
      return nil
    }
    srcBuffer.frameLength = frameCount

    if srcFormat.channelCount == 1 { return srcBuffer }

    guard
      let monoFormat = AVAudioFormat(standardFormatWithSampleRate: srcFormat.sampleRate, channels: 1),
      let converter = AVAudioConverter(from: srcFormat, to: monoFormat)
    else { return nil }

    let dstCapacity = AVAudioFrameCount(Double(frameCount) / converter.inputFormat.sampleRate
      * converter.outputFormat.sampleRate) + 32
    guard let mono = AVAudioPCMBuffer(pcmFormat: monoFormat, frameCapacity: dstCapacity) else { return nil }

    var consumed = false
    var error: NSError?
    converter.convert(to: mono, error: &error) { _, outStatus in
      if consumed {
        outStatus.pointee = .noDataNow
        return nil
      }
      consumed = true
      outStatus.pointee = .haveData
      return srcBuffer
    }
    if let error {
      print("[Ponged] Mono convert failed: \(error)")
      return nil
    }
    return mono
  }

  private func ensurePlaybackReady() {
    try? AVAudioSession.sharedInstance().setActive(true)
    if !engine.isRunning { startEngine() }
    if !player.isPlaying { player.play() }
  }

  func duration(for preset: SoundPreset) -> TimeInterval {
    durations[preset] ?? 0.5
  }

  func stopAll() {
    loopTimer?.invalidate()
    loopTimer = nil
    stopTravel()
    if player.isPlaying { player.stop() }
  }

  func applySpatial(_ position: CellSpatialPosition) {
    currentSpatial = position
    debugPositionLabel = String(
      format: "x:%.1f y:%.1f z:%.1f",
      position.x, position.y, position.z
    )

    switch outputMode {
    case .hrtf:
      player.position = position.point
      player.volume = 1
    case .stereoPan:
      playerMixer.pan = max(-1, min(1, position.x / 1.2))
      playerMixer.outputVolume = 1
    }
  }

  func playOnce(
    preset: SoundPreset,
    at cell: GridCell? = nil,
    gridColumns: Int? = nil,
    gridRows: Int? = nil,
    useCurrentSpatial: Bool = false
  ) {
    guard let buffer = monoBuffers[preset] else {
      print("[Ponged] No buffer for \(preset) (loaded=\(loadedPresetCount))")
      return
    }
    guard engine.isRunning else {
      print("[Ponged] Engine not running")
      return
    }

    if useCurrentSpatial {
      applySpatial(currentSpatial)
    } else if let cell {
      let cols = gridColumns ?? MechanicConfig.shared.gridColumns
      let rows = gridRows ?? MechanicConfig.shared.gridRows
      applySpatial(SpatialTable.position(for: cell, columns: cols, rows: rows))
    } else {
      applySpatial(currentSpatial)
    }

    ensurePlaybackReady()
    player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
  }

  func playPreviewLoops(preset: SoundPreset, at cell: GridCell, count: Int, completion: @escaping () -> Void) {
    var remaining = count
    let gap = MechanicConfig.shared.loopGap
    let clipDuration = duration(for: preset)

    func scheduleNext() {
      guard remaining > 0 else {
        completion()
        return
      }
      playOnce(preset: preset, at: cell)
      remaining -= 1
      if remaining > 0 {
        loopTimer?.invalidate()
        loopTimer = Timer.scheduledTimer(withTimeInterval: clipDuration + gap, repeats: false) { _ in
          Task { @MainActor in scheduleNext() }
        }
      } else {
        loopTimer = Timer.scheduledTimer(withTimeInterval: clipDuration, repeats: false) { _ in
          Task { @MainActor in completion() }
        }
      }
    }
    scheduleNext()
  }

  func startTravel(ping: Ping, onComplete: @escaping () -> Void) {
    stopTravel()
    travelCompletion = onComplete
    isTraveling = true
    travelLoopsPlayed = 0

    let loopCount = SpatialTable.travelLoopCount(from: ping.startCell, to: ping.endCell)
    travelWaypoints = SpatialTable.waypoints(from: ping.startCell, to: ping.endCell, count: loopCount)

    let preset = ping.preset
    let clipDuration = duration(for: preset)
    let gap = MechanicConfig.shared.loopGap

    func scheduleLoop() {
      guard isTraveling, travelLoopsPlayed < travelWaypoints.count else { return }

      applySpatial(travelWaypoints[travelLoopsPlayed])
      playOnce(preset: preset, useCurrentSpatial: true)
      travelLoopsPlayed += 1

      loopTimer?.invalidate()
      let isLast = travelLoopsPlayed >= travelWaypoints.count
      let wait = isLast ? clipDuration : clipDuration + gap
      loopTimer = Timer.scheduledTimer(withTimeInterval: wait, repeats: false) { _ in
        Task { @MainActor in
          if isLast {
            self.finishTravel()
          } else {
            scheduleLoop()
          }
        }
      }
    }
    scheduleLoop()
  }

  private func finishTravel() {
    isTraveling = false
    loopTimer?.invalidate()
    loopTimer = nil
    if let last = travelWaypoints.last { applySpatial(last) }
    travelCompletion?()
    travelCompletion = nil
    travelWaypoints = []
    travelLoopsPlayed = 0
  }

  private func stopTravel() {
    isTraveling = false
    loopTimer?.invalidate()
    loopTimer = nil
    travelWaypoints = []
    travelLoopsPlayed = 0
  }
}
