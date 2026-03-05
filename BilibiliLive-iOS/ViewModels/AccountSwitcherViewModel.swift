import Combine
import Foundation

@MainActor
@Observable
final class AccountSwitcherViewModel {
  var accounts: [AccountManagerIOS.Account] = []

  init() {
    loadAccounts()
  }

  func loadAccounts() {
    accounts = AccountManagerIOS.shared.accounts
  }

  func switchAccount(to account: AccountManagerIOS.Account) {
    AccountManagerIOS.shared.setActiveAccount(mid: account.profile.mid)
  }
}
