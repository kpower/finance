import Foundation

/// Top-level sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
  case balance
  case savings
  case savingsYears

  var id: Self { self }

  var title: LocalizedStringResource {
    switch self {
    case .balance: .sidebarSectionBalanceTitle
    case .savings: .sidebarSectionSavingsTitle
    case .savingsYears: .sidebarSectionSavingsYearsTitle
    }
  }

  var systemImage: String {
    switch self {
    case .balance: "clock.arrow.circlepath"
    case .savings: "banknote"
    case .savingsYears: "calendar"
    }
  }
}
