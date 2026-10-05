/// Top-level sections shown in the sidebar.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
  case deposits
  case history
  case rates

  var id: Self { self }

  var title: String {
    switch self {
    case .deposits: "Вклады"
    case .history: "История"
    case .rates: "Курсы валют"
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
