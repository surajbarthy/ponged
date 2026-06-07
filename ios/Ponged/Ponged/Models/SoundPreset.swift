import Foundation

enum SoundPreset: String, CaseIterable, Codable, Identifiable, Hashable {
  case heeHee = "hee_hee"
  case aaow = "aaow"

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .heeHee: return "Hee Hee!"
    case .aaow: return "Aaow!"
    }
  }

  /// Bundled resource name without extension.
  var resourceName: String { rawValue }

  var resourceExtension: String { "mp3" }
}
