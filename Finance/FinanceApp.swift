import SwiftData
import SwiftUI

@main
struct FinanceApp: App {
  var body: some Scene {
    // Explicit id: the window frame is autosaved under a key built from it. Without one the key
    // comes from the root view's type name, which is not stable across launches.
    WindowGroup(id: "main") {
      MainView()
        .backupSupport()
        .frame(minWidth: 900, minHeight: 500)
    }
    .modelContainer(for: FinanceSchema.models)
    .commands {
      BackupCommands()
    }
    Settings {
      SettingsView()
    }
  }
}
