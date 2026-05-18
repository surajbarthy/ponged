import SwiftUI

struct PickSoundView: View {
  var recipientHint: String?
  var onPick: (SoundPreset) -> Void

  var body: some View {
    ZStack {
      Color(red: 1, green: 0.92, blue: 0.4).ignoresSafeArea()
      VStack(spacing: 20) {
        if let hint = recipientHint {
          Text("Throw back at \(hint)!")
            .font(.title2.bold())
        } else {
          Text("Pick a sound")
            .font(.title.bold())
        }
        ForEach(SoundPreset.allCases) { preset in
          Button(preset.displayName) { onPick(preset) }
            .font(.title.bold())
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 4)
        }
      }
      .padding()
    }
  }
}
