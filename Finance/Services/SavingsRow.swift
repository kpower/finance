import Foundation
import SwiftData

/// One line of the savings table: an entry and what is calculated from it.
struct SavingsRow: Identifiable {
  let id: PersistentIdentifier
  let date: Date
  let grossMonthly: Double
  let expenses: [ExpenseBlock]
  let comment: String
  let outcome: SavingsOutcome
}

/// What the calculation takes from an entry, stored or still being edited.
struct SavingsInput {
  /// Start of the entry's day.
  let date: Date
  let grossMonthly: Double
  let expensesTotal: Double
}

enum SavingsOutcome {
  case figures(SavingsFigures)
  case missing(SavingsGap)

  var figures: SavingsFigures? {
    switch self {
    case let .figures(figures): figures
    case .missing: nil
    }
  }
}

/// Data of a year an entry depends on that is not entered yet.
enum SavingsGap: Error {
  case parameters(year: Int)
  case inflation(year: Int)
}

/// Calculated amounts of an entry, all per month.
struct SavingsFigures {
  let net: Double
  /// Spendable income (net minus expenses) of the earliest entry, raised by inflation up to this entry.
  let startMoney: Double
  /// Spendable income above `startMoney`.
  let delta: Double
  /// The share of the net income that is saved no matter what.
  let savedShare: Double
  /// What to save on top of `savedShare`.
  let saveMonthly: Double
}
