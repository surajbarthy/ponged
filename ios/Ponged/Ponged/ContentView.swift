import SwiftUI

struct ContentView: View {
  @State private var session = GameSession()
  @State private var path = NavigationPath()

  var body: some View {
    NavigationStack(path: $path) {
      HomeView(session: session) {
        path.append(AppRoute.pickSound)
      }
      .navigationDestination(for: AppRoute.self) { route in
        switch route {
        case .home:
          EmptyView()
        case .pickSound:
          PickSoundView(recipientHint: session.returnRecipientName) { preset in
            path.append(AppRoute.throwSound(preset))
          }
        case .throwSound(let preset):
          ThrowView(session: session, preset: preset) { ping in
            path.append(AppRoute.handoff(ping))
          }
        case .handoff(let ping):
          HandoffView(ping: ping) {
            path.append(AppRoute.receive(ping))
          }
        case .receive(let ping):
          ReceiveView(ping: ping, session: session) {
            path.append(AppRoute.success(ping))
          }
        case .success(let ping):
          SuccessView(ping: ping) {
            path.removeLast(path.count)
            path.append(AppRoute.pickSound)
          }
        }
      }
    }
  }
}
