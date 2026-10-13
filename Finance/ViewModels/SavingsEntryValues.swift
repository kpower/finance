import Foundation

/// A line of the Savings section: monthly income and regular expenses as they were on a given day.
struct SavingsEntryValues {
  /// Start of the entry's day.
  let date: Date
  let grossMonthly: Double
  let expenses: [ExpenseBlock]
  let comment: String
}
