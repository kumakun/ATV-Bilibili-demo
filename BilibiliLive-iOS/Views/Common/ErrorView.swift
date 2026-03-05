import SwiftUI

struct ErrorView: View {
  let error: Error
  let retryAction: () -> Void

  var body: some View {
    VStack {
      Text("An error occurred: \(error.localizedDescription)")
      Button("Retry") {
        retryAction()
      }
    }
  }
}
