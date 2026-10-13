import Foundation
import SwiftData

/// A stored line of the Savings section: monthly income and regular expenses as they were on a given day.
@Model
final class SavingsEntry {
  /// Start of the day the entry belongs to: its key, one entry per day.
  @Attribute(.unique) var date: Date
  var grossMonthly: Double
  var expenses: [ExpenseRecord]
  var comment: String

  init(date: Date, grossMonthly: Double, expenses: [ExpenseRecord], comment: String) {
    self.date = date
    self.grossMonthly = grossMonthly
    self.expenses = expenses
    self.comment = comment
  }
}

/// A thematic block of regular monthly expenses, e.g. a mortgage or a kindergarten.
struct ExpenseRecord: Codable {
  let name: String
  let content: Content

  enum Content: Codable {
    case single(amount: Double)
    /// Entered part by part, e.g. principal and interest of a mortgage.
    case split(parts: [ExpensePartRecord])
  }
}

struct ExpensePartRecord: Codable {
  let name: String
  let amount: Double
}
