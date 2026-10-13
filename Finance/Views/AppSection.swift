import Foundation

/// Top-level sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
  case history
  case savings

  var id: Self { self }

  var title: LocalizedStringResource {
    switch self {
    case .history: .sidebarSectionHistoryTitle
    case .savings: .sidebarSectionSavingsTitle
    }
  }

  var systemImage: String {
    switch self {
    case .history: "clock.arrow.circlepath"
    case .savings: "banknote"
    }
  }
}
