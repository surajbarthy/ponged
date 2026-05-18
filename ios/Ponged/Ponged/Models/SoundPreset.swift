import Foundation

enum SoundPreset: String, CaseIterable, Codable, Identifiable {
    case pow
    case zap
    case crash

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .pow: return "POW!"
        case .zap: return "ZAP!"
        case .crash: return "CRASH!"
        }
    }

    /// Base frequency for synthesized placeholder SFX (Hz).
    var baseFrequency: Double {
        switch self {
        case .pow: return 180
        case .zap: return 420
        case .crash: return 95
        }
    }

    /// Approximate clip length for loop scheduling (seconds).
    var approximateDuration: TimeInterval {
        switch self {
        case .pow: return 0.22
        case .zap: return 0.18
        case .crash: return 0.35
        }
    }
}
