import SwiftUI

struct HomeView: View {
  @Bindable var session: GameSession
  var onPlay: () -> Void

  var body: some View {
    ZStack {
      Color.yellow.ignoresSafeArea()
      VStack(spacing: 24) {
        Text("PONGED!")
          .font(.system(size: 48, weight: .black, design: .rounded))
          .foregroundStyle(.red)
        Text("You just got ponged.")
          .font(.headline)
        TextField("Your name", text: $session.playerName)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal, 32)
        Button("Play") { onPlay() }
          .buttonStyle(.borderedProminent)
          .tint(.red)
          .disabled(session.playerName.trimmingCharacters(in: .whitespaces).isEmpty)
      }
    }
  }
}
