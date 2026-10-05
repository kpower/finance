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
  @State private var message: Message?

  private struct Message: Identifiable {
    let id = UUID()
    let title: String
    let text: String
  }

  func body(content: Content) -> some View {
    content
      .focusedSceneValue(\.backupActions, BackupActions(export: export, restore: { isImporting = true }))
      .fileExporter(
        isPresented: Binding(get: { exportDocument != nil }, set: { if !$0 { exportDocument = nil } }),
        document: exportDocument,
        contentType: .json,
        defaultFilename: defaultFilename
      ) { result in
        if case .failure(let error) = result {
          message = Message(title: "Не удалось сохранить бэкап", text: error.localizedDescription)
        }
      }
      .fileImporter(isPresented: $isImporting, allowedContentTypes: [.json]) { result in
        load(result)
      }
      .confirmationDialog(
        "Заменить все данные содержимым бэкапа?",
        isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }),
        titleVisibility: .visible,
        presenting: pendingRestore
      ) { backup in
        Button("Заменить", role: .destructive) { restore(backup) }
        Button("Отмена", role: .cancel) {}
      } message: { backup in
        Text("""
          Бэкап от \(Fmt.date(backup.exportedAt)): вкладов — \(backup.deposits.count), \
          курсов — \(backup.rates.count), записей истории — \(backup.snapshots.count). \
          Текущие данные будут удалены.
          """)
      }
      .alert(item: $message) { message in
        Alert(title: Text(message.title), message: Text(message.text), dismissButton: .default(Text("OK")))
      }
  }

  private var defaultFilename: String {
    "Finance-backup-\(Date.now.formatted(.iso8601.year().month().day()))"
  }

  private func export() {
    do {
      exportDocument = BackupDocument(data: try BackupService.encode(BackupService.makeBackup(from: context)))
    } catch {
      message = Message(title: "Не удалось сохранить бэкап", text: error.localizedDescription)
    }
  }

  private func load(_ result: Result<URL, any Error>) {
    do {
      let url = try result.get()
      let accessing = url.startAccessingSecurityScopedResource()
      defer { if accessing { url.stopAccessingSecurityScopedResource() } }
      pendingRestore = try BackupService.decode(Data(contentsOf: url))
    } catch {
      message = Message(title: "Не удалось загрузить бэкап", text: error.localizedDescription)
    }
  }

  private func restore(_ backup: Backup) {
    do {
      try BackupService.restore(backup, into: context)
      message = Message(title: "Бэкап загружен", text: "Данные восстановлены из бэкапа от \(Fmt.date(backup.exportedAt)).")
    } catch {
      message = Message(title: "Не удалось загрузить бэкап", text: error.localizedDescription)
    }
  }
}
