import SwiftUI

struct HandoffView: View {
  let ping: Ping
  var onContinue: () -> Void

  var body: some View {
    ZStack {
      Color.pink.opacity(0.85).ignoresSafeArea()
      VStack(spacing: 24) {
        Text("\(ping.senderName.uppercased()) HAS PINGED YOU!")
          .font(.title2.bold())
          .multilineTextAlignment(.center)
          .padding()
        Text("Hand the phone to your friend")
          .font(.headline)
        Button("I'm ready to catch") { onContinue() }
          .buttonStyle(.borderedProminent)
          .tint(.white)
      }
      .foregroundStyle(.white)
      .padding()
    }
  }
}
