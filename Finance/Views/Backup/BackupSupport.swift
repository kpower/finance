import SwiftData
import SwiftUI
import UniformTypeIdentifiers

extension View {
  /// Save/load backups for this window; triggered from the File menu (`BackupCommands`).
  func backupSupport() -> some View {
    modifier(BackupSupport())
  }
}

private struct BackupSupport: ViewModifier {
  @Environment(\.modelContext) private var context

  @State private var exportDocument: BackupDocument?
  @State private var isImporting = false
  @State private var pendingRestore: Backup?
  @State private var message: BackupMessage?
  @State private var restoreCount = 0

  func body(content: Content) -> some View {
    content
      // A restore replaces every stored entry, so the window starts over
      // instead of keeping screens that hold the old ones.
      .id(restoreCount)
      .focusedSceneValue(\.backupActions, BackupActions(export: export, restore: { isImporting = true }))
      .fileExporter(
        isPresented: Binding(get: { exportDocument != nil }, set: { if !$0 { exportDocument = nil } }),
        document: exportDocument,
        contentType: .json,
        defaultFilename: defaultFilename
      ) { result in
        switch result {
        case .success:
          break
        case .failure:
          message = BackupMessage(
            title: String(localized: .backupExportAlertWriteFailedTitle),
            text: String(localized: .backupExportAlertWriteFailedMessage)
          )
        }
      }
      .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
        load(result)
      }
      .confirmationDialog(
        Text(.backupRestoreDialogTitle),
        isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }),
        titleVisibility: .visible,
        presenting: pendingRestore
      ) { backup in
        Button(role: .destructive) { restore(backup) } label: { Text(.backupRestoreDialogReplaceButton) }
        Button(role: .cancel) {} label: { Text(.backupRestoreDialogCancelButton) }
      } message: { backup in
        Text(.backupRestoreDialogMessage(Fmt.date(backup.exportedAt), backup.snapshots.count))
      }
      .alert(item: $message) { message in
        Alert(title: Text(message.title), message: Text(message.text), dismissButton: .default(Text(.backupAlertOkButton)))
      }
  }

  private var defaultFilename: String {
    "Finance-backup-\(Date.now.formatted(.iso8601.year().month().day()))"
  }

  private func export() {
    do {
      exportDocument = BackupDocument(data: try BackupService.encode(BackupService.makeBackup(from: context)))
    } catch {
      message = BackupMessage(
        title: String(localized: .backupExportAlertCreateFailedTitle),
        text: String(localized: .backupExportAlertCreateFailedMessage)
      )
    }
  }

  private func load(_ result: Result<URL, any Error>) {
    do {
      let url = try result.get()
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      pendingRestore = try BackupService.decode(Data(contentsOf: url))
    } catch let BackupError.unsupportedVersion(version) {
      message = BackupMessage(
        title: String(localized: .backupImportAlertOpenFailedTitle),
        text: String(localized: .backupImportAlertUnsupportedVersionMessage(version))
      )
    } catch {
      message = BackupMessage(
        title: String(localized: .backupImportAlertOpenFailedTitle),
        text: String(localized: .backupImportAlertUnreadableMessage)
      )
    }
  }

  private func restore(_ backup: Backup) {
    do {
      try BackupService.restore(backup, into: context)
      restoreCount += 1
      message = BackupMessage(
        title: String(localized: .backupImportAlertRestoredTitle),
        text: String(localized: .backupImportAlertRestoredMessage(Fmt.date(backup.exportedAt)))
      )
    } catch {
      message = BackupMessage(
        title: String(localized: .backupImportAlertRestoreFailedTitle),
        text: String(localized: .backupImportAlertRestoreFailedMessage)
      )
    }
  }
}

private struct BackupMessage: Identifiable {
  let id = UUID()
  let title: String
  let text: String
}
