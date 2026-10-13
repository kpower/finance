import Foundation

/// A history entry: all deposits, or only their currency totals, and the rates on a given day.
struct SnapshotValues {
  /// Start of the entry's day.
  let date: Date
  let rates: Rates
  let content: SnapshotContent
  let comment: String
}

enum SnapshotContent: Equatable {
  case detailed([Deposit])
  /// Archive entry: only currency totals, no per-deposit details.
  case summaryOnly(CurrencyAmounts)
}

enum SnapshotKind: CaseIterable {
  case detailed
  case summaryOnly
}

extension SnapshotContent {
  var kind: SnapshotKind {
    switch self {
    case .detailed: .detailed
    case .summaryOnly: .summaryOnly
    }
  }

  /// Empty for an archive entry.
  var deposits: [Deposit] {
    switch self {
    case let .detailed(deposits): deposits
    case .summaryOnly: []
    }
  }

  /// Totals by currency: summed over the deposits, or the ones an archive entry was entered with.
  var sums: CurrencyAmounts {
    switch self {
    case let .detailed(deposits):
      CurrencyAmounts(
        rub: deposits.reduce(0) { $0 + ($1.amountRUB ?? 0) },
        usd: deposits.reduce(0) { $0 + ($1.amountUSD ?? 0) },
        eur: deposits.reduce(0) { $0 + ($1.amountEUR ?? 0) }
      )
    case let .summaryOnly(totals):
      totals
    }
  }
}
