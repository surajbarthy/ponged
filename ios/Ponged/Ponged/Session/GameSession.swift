import Foundation
import Observation

enum AppRoute: Hashable {
  case home
  case pickSound
  case throwSound(SoundPreset)
  case handoff(Ping)
  case receive(Ping)
  case success(Ping)
}

@Observable
@MainActor
final class GameSession {
  var playerName: String = ""
  var round: Int = 1
  var currentPing: Ping?
  var useGyroThrow: Bool = false
  var debugTapCatchCount: Int = 0

  var returnRecipientName: String? {
    currentPing?.senderName
  }

  func makePing(preset: SoundPreset, start: GridCell, end: GridCell, vector: ThrowVector?) -> Ping {
    let ping = Ping(
      preset: preset,
      startCell: start,
      endCell: end,
      throwVector: vector,
      senderName: playerName.isEmpty ? "Player" : playerName,
      round: round
    )
    currentPing = ping
    return ping
  }

  func markCaught() {
    if var ping = currentPing {
      ping.status = .caught
      currentPing = ping
    }
    round += 1
  }
}
