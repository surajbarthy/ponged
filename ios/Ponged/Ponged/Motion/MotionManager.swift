import CoreMotion
import Foundation

@MainActor
final class MotionManager: ObservableObject {
    private let manager = CMMotionManager()
    @Published private(set) var pitch: Double = 0
    @Published private(set) var yaw: Double = 0
    @Published private(set) var roll: Double = 0
    @Published private(set) var peakAccel: Double = 0

    private var accelSamples: [Double] = []

    func startUpdates() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let motion else { return }
            let attitude = motion.attitude
            self.pitch = attitude.pitch * 180 / .pi
            self.yaw = attitude.yaw * 180 / .pi
            self.roll = attitude.roll * 180 / .pi
            let accel = motion.userAcceleration
            let mag = sqrt(accel.x * accel.x + accel.y * accel.y + accel.z * accel.z)
            self.accelSamples.append(mag)
            if self.accelSamples.count > 30 {
                self.accelSamples.removeFirst()
            }
            self.peakAccel = self.accelSamples.max() ?? 0
        }
    }

    func stopUpdates() {
        manager.stopDeviceMotionUpdates()
        accelSamples.removeAll()
    }

    func snapshotVector() -> ThrowVector {
        ThrowVector(pitch: pitch, yaw: yaw, peakAccel: peakAccel)
    }
}
