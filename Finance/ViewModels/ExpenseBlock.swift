import Foundation

/// A thematic block of regular monthly expenses, e.g. a mortgage or a kindergarten.
struct ExpenseBlock: Hashable, Identifiable, Sendable {
  /// Tells the blocks of a screen apart and nothing else: it is not stored.
  let id = UUID()
  var name: String
  var content: Content

  enum Content: Hashable, Sendable {
    case single(amount: Double)
    /// Entered part by part, e.g. principal and interest of a mortgage.
    case split(parts: [ExpensePart])
  }
}

struct ExpensePart: Hashable, Identifiable, Sendable {
  let id = UUID()
  var name: String
  var amount: Double
}

extension ExpenseBlock {
  /// Empty for a block with a single amount.
  var parts: [ExpensePart] {
    switch content {
    case .single: []
    case let .split(parts): parts
    }
  }

  var total: Double {
    switch content {
    case let .single(amount): amount
    case let .split(parts): parts.reduce(0) { $0 + $1.amount }
    }
  }

  /// Adds a blank part for the user to fill in; a single amount becomes the first part.
  mutating func addPart() {
    let blank = ExpensePart(name: "", amount: 0)
    switch content {
    case let .single(amount): content = .split(parts: [ExpensePart(name: "", amount: amount), blank])
    case let .split(parts): content = .split(parts: parts + [blank])
    }
  }

  mutating func replacePart(_ part: ExpensePart) {
    content = .split(parts: parts.map { $0.id == part.id ? part : $0 })
  }

  /// Removing the only part turns its amount back into the block's single amount.
  mutating func removePart(_ part: ExpensePart) {
    let remaining = parts.filter { $0.id != part.id }
    content = remaining.isEmpty ? .single(amount: part.amount) : .split(parts: remaining)
  }
}

extension [ExpenseBlock] {
  var total: Double { reduce(0) { $0 + $1.total } }
}
