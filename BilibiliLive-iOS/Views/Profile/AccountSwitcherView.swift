import SwiftUI

struct AccountSwitcherView: View {
  @State var viewModel = AccountSwitcherViewModel()
  @Environment(\.presentationMode) var presentationMode

  var body: some View {
    NavigationView {
      List {
        ForEach(viewModel.accounts, id: \.profile.mid) { account in
          Button(action: {
            viewModel.switchAccount(to: account)
            presentationMode.wrappedValue.dismiss()
          }) {
            HStack {
              AsyncImage(url: URL(string: account.profile.avatar)) { image in
                image.resizable()
                  .aspectRatio(contentMode: .fit)
              } placeholder: {
                ProgressView()
              }
              .frame(width: 40, height: 40)
              .clipShape(Circle())

              Text(account.profile.username)

              Spacer()

              if account.profile.mid == AccountManagerIOS.shared.currentAccount?.profile.mid {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.accentColor)
              }
            }
          }
        }

        Button(action: {
          // Navigate to login view
        }) {
          HStack {
            Image(systemName: "plus.circle.fill")
            Text("添加新账号")
          }
        }
      }
      .navigationTitle("切换账号")
      .navigationBarItems(
        trailing: Button("关闭") {
          presentationMode.wrappedValue.dismiss()
        })
    }
    .onAppear {
      viewModel.loadAccounts()
    }
  }
}
