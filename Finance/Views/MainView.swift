import SwiftData
import SwiftUI

struct MainView: View {
  @SceneStorage("selectedSection") private var selection: AppSection = .deposits

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
      switch selection {
      case .deposits: DepositsView()
      case .history: HistoryView()
      case .rates: RatesView()
      }
    }
  }

  /// List selection is optional; keep a section always selected.
  private var sidebarSelection: Binding<AppSection?> {
    Binding(get: { selection }, set: { if let new = $0 { selection = new } })
  }
}

#Preview {
  MainView()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
