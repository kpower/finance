import Foundation
import SwiftData

// MARK: - Reading

extension SavingsEntryValues {
  init(_ entry: SavingsEntry) {
    self.init(
      date: entry.date, grossMonthly: entry.grossMonthly,
      expenses: entry.expenses.map { ExpenseBlock($0) }, comment: entry.comment
    )
  }
}

extension Stored<SavingsEntryValues> {
  init(_ entry: SavingsEntry) {
    self.init(id: entry.persistentModelID, values: SavingsEntryValues(entry))
  }
}

extension ExpenseBlock {
  fileprivate init(_ record: ExpenseRecord) {
    let content: Content =
      switch record.content {
      case let .single(amount): .single(amount: amount)
      case let .split(parts): .split(parts: parts.map { ExpensePart(name: $0.name, amount: $0.amount) })
      }
    self.init(name: record.name, content: content)
  }
}

// MARK: - Writing

extension SavingsEntry {
  convenience init(_ values: SavingsEntryValues) {
    self.init(
      date: Calendar.current.startOfDay(for: values.date), grossMonthly: values.grossMonthly,
      expenses: values.expenses.map { ExpenseRecord($0) }, comment: values.comment
    )
  }

  func update(from values: SavingsEntryValues) {
    date = Calendar.current.startOfDay(for: values.date)
    grossMonthly = values.grossMonthly
    expenses = values.expenses.map { ExpenseRecord($0) }
    comment = values.comment
  }
}

extension ExpenseRecord {
  fileprivate init(_ block: ExpenseBlock) {
    let content: Content =
      switch block.content {
      case let .single(amount): .single(amount: amount)
      case let .split(parts): .split(parts: parts.map { ExpensePartRecord(name: $0.name, amount: $0.amount) })
      }
    self.init(name: block.name, content: content)
  }
}
