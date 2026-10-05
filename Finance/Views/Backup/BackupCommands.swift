import SwiftUI

/// File menu items for backups; the actions come from the focused window.
struct BackupCommands: Commands {
  @FocusedValue(\.backupActions) private var actions

  var body: some Commands {
    CommandGroup(replacing: .importExport) {
      Button("Сохранить бэкап…") { actions?.export() }
        .keyboardShortcut("s", modifiers: [.command, .shift])
        .disabled(actions == nil)
      Button("Загрузить бэкап…") { actions?.restore() }
        .keyboardShortcut("o", modifiers: [.command, .shift])
        .disabled(actions == nil)
    }
  }
}

/// Backup actions published by the focused window for `BackupCommands`.
struct BackupActions {
  var export: @MainActor () -> Void
  var restore: @MainActor () -> Void
}

extension FocusedValues {
  @Entry var backupActions: BackupActions?
}
