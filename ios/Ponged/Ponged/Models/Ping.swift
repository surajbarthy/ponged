import Foundation

enum PingStatus: String, Codable {
    case sent
    case caught
}

struct ThrowVector: Codable, Equatable {
    var pitch: Double
    var yaw: Double
    var peakAccel: Double
}

struct Ping: Identifiable, Codable, Equatable, Hashable {
    var id: UUID = UUID()
    var preset: SoundPreset
    var startCell: GridCell
    var endCell: GridCell
    var throwVector: ThrowVector?
    var senderName: String
    var status: PingStatus = .sent
    var round: Int
}
