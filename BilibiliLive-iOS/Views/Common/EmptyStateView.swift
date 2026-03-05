import SwiftUI

struct EmptyStateView: View {
  let message: String

  var body: some View {
    VStack {
      Image(systemName: "tray.fill")
        .font(.largeTitle)
        .foregroundColor(.secondary)
      Text(message)
        .font(.headline)
        .foregroundColor(.secondary)
    }
  }
}
