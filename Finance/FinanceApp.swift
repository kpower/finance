import SwiftData
import SwiftUI

@main
struct FinanceApp: App {
  var body: some Scene {
    WindowGroup {
      MainView()
        .backupSupport()
        .frame(minWidth: 900, minHeight: 500)
    }
    .modelContainer(for: FinanceSchema.models)
    .commands {
      BackupCommands()
    }
  }
}
