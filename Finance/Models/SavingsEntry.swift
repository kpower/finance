import Foundation
import SwiftData

/// A line of the Savings section: monthly income and regular expenses as they were on a given day.
@Model
final class SavingsEntry {
  /// Start of the day the entry belongs to: its key, one entry per day.
  @Attribute(.unique) var date: Date
  var grossMonthly: Double
  var expenses: [ExpenseBlock]
  var comment: String

  init(date: Date, grossMonthly: Double, expenses: [ExpenseBlock], comment: String) {
    self.date = Calendar.current.startOfDay(for: date)
    self.grossMonthly = grossMonthly
    self.expenses = expenses
    self.comment = comment
  }

  var input: SavingsInput {
    SavingsInput(date: date, grossMonthly: grossMonthly, expensesTotal: expenses.total)
  }
}
