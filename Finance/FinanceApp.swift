import SwiftData
import SwiftUI

@main
struct FinanceApp: App {
  /// One container for the main window and Settings, so a change made in one shows in the other.
  private let container: ModelContainer

  init() {
    do {
      container = try ModelContainer(for: Schema(FinanceSchema.models))
    } catch {
      fatalError("The data store could not be opened: \(error)")
    }
  }

  var body: some Scene {
    // Explicit id: the window frame is autosaved under a key built from it. Without one the key
    // comes from the root view's type name, which is not stable across launches.
    WindowGroup(id: "main") {
      MainView()
        .backupSupport()
        .frame(minWidth: 900, minHeight: 500)
    }
    .modelContainer(container)
    .commands {
      BackupCommands()
    }
    Settings {
      SettingsView()
    }
    .modelContainer(container)
  }
}
