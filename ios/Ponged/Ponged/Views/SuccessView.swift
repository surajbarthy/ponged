import SwiftUI

struct SuccessView: View {
  let ping: Ping
  var onContinue: () -> Void
  @State private var didContinue = false

  var body: some View {
    ZStack {
      Color.green.ignoresSafeArea()
      VStack(spacing: 24) {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 80))
          .foregroundStyle(.white)
        Text("SUCCESSFUL HIT!")
          .font(.largeTitle.bold())
          .foregroundStyle(.white)
        Text("\(ping.preset.displayName) from \(ping.senderName)")
          .foregroundStyle(.white.opacity(0.9))
        Button("Throw back") { onContinue() }
          .buttonStyle(.borderedProminent)
          .tint(.white)
      }
    }
    .onAppear {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
        guard !didContinue else { return }
        didContinue = true
        onContinue()
      }
    }
  }
}
