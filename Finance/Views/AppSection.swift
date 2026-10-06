import Foundation

/// Top-level sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
  case deposits
  case history
  case rates

  var id: Self { self }

  var title: LocalizedStringResource {
    switch self {
    case .deposits: .sidebarSectionDepositsTitle
    case .history: .sidebarSectionHistoryTitle
    case .rates: .sidebarSectionRatesTitle
    }
  }

  var systemImage: String {
    switch self {
    case .deposits: "banknote"
    case .history: "clock.arrow.circlepath"
    case .rates: "dollarsign.arrow.circlepath"
    }
  }
}
