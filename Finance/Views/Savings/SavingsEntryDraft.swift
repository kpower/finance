import Foundation

/// Editable copy of a savings entry: what the entry screen shows and compares with the saved values.
/// The entry itself changes only when the user saves.
struct SavingsEntryDraft: Equatable {
  /// Start of the entry's day.
  var date: Date
  /// Nil until entered: the very first entry starts without an income.
  var grossMonthly: Double?
  var expenses: [ExpenseBlock]
  var comment: String
}

extension SavingsEntryDraft {
  init(_ entry: SavingsEntry) {
    self.init(date: entry.date, grossMonthly: entry.grossMonthly, expenses: entry.expenses, comment: entry.comment)
  }

  /// An entry for today that is not stored yet, with the income and expenses of `latest`.
  static func newEntry(after latest: SavingsEntry?) -> SavingsEntryDraft {
    SavingsEntryDraft(
      date: Calendar.current.startOfDay(for: .now), grossMonthly: latest?.grossMonthly,
      expenses: latest?.expenses ?? [], comment: ""
    )
  }
}
