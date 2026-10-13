import Foundation

/// Amount fields shared by a stored history entry and its editable copy.
protocol SnapshotAmounts {
  var kind: Snapshot.Kind { get }
  var items: [DepositRecord] { get }
  var summaryRUB: Double { get }
  var summaryUSD: Double { get }
  var summaryEUR: Double { get }
}

extension SnapshotAmounts {
  var sumRUB: Double {
    switch kind {
    case .summaryOnly: summaryRUB
    case .detailed: items.reduce(0) { $0 + ($1.amountRUB ?? 0) }
    }
  }

  var sumUSD: Double {
    switch kind {
    case .summaryOnly: summaryUSD
    case .detailed: items.reduce(0) { $0 + ($1.amountUSD ?? 0) }
    }
  }

  var sumEUR: Double {
    switch kind {
    case .summaryOnly: summaryEUR
    case .detailed: items.reduce(0) { $0 + ($1.amountEUR ?? 0) }
    }
  }

  func totalRUB(at rates: Rates) -> Double {
    sumRUB + sumUSD * rates.usd + sumEUR * rates.eur
  }
}
