import SwiftData
import SwiftUI

struct MainView: View {
  @SceneStorage("selectedSection") private var selection = AppSection.history
  /// Screens pushed over the selected section's table. They belong to that section,
  /// so the path is emptied when another one is selected.
  @State private var path = NavigationPath()
  @State private var hasUnsavedEdits = false
  /// Section asked for while an entry with unsaved edits is open; set until the user decides.
  @State private var pendingSelection: AppSection?

  var body: some View {
    NavigationSplitView {
      List(AppSection.allCases, selection: sidebarSelection) { section in
        Label {
          Text(section.title)
        } icon: {
          Image(systemName: section.systemImage)
        }
        .tag(section)
      }
      .navigationSplitViewColumnWidth(min: 160, ideal: 190)
    } detail: {
      // One stack for all sections. A stack per section, swapped with the selection, crashes
      // inside SwiftUI when a section is left with a screen pushed.
      NavigationStack(path: $path) {
        switch selection {
        case .history: HistoryView(path: $path)
        case .savings: SavingsView(path: $path)
        }
      }
    }
    .environment(\.unsavedEdits, $hasUnsavedEdits)
    .onChange(of: path.isEmpty) {
      // A screen with unsaved edits may be covered by another one, so it cannot take its report
      // back when it disappears. With nothing pushed there is no such screen.
      if path.isEmpty { hasUnsavedEdits = false }
    }
    .confirmationDialog(
      Text(.sidebarUnsavedDialogTitle),
      isPresented: Binding(get: { pendingSelection != nil }, set: { if !$0 { pendingSelection = nil } }),
      titleVisibility: .visible,
      presenting: pendingSelection
    ) { section in
      Button(role: .destructive) { show(section) } label: { Text(.sidebarUnsavedDialogDiscardButton) }
      Button(role: .cancel) {} label: { Text(.sidebarUnsavedDialogCancelButton) }
    } message: { _ in
      Text(.sidebarUnsavedDialogMessage)
    }
  }

  /// List selection is optional; keep a section always selected.
  private var sidebarSelection: Binding<AppSection?> {
    Binding(
      get: { selection },
      set: { newValue in
        guard let newValue, newValue != selection else { return }
        if hasUnsavedEdits {
          pendingSelection = newValue
        } else {
          show(newValue)
        }
      }
    )
  }

  private func show(_ section: AppSection) {
    path = NavigationPath()
    selection = section
  }
}

#Preview {
  MainView()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
