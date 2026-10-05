import Foundation

/// Common money fields shared by a live deposit and its frozen copy in a snapshot.
protocol DepositAmounts {
  var amountRUB: Double? { get }
  var amountUSD: Double? { get }
  var amountEUR: Double? { get }
}

extension DepositAmounts {
  /// Whole deposit converted to rubles at the given rates.
  func totalRUB(at rates: Rates) -> Double {
    (amountRUB ?? 0) + (amountUSD ?? 0) * rates.usd + (amountEUR ?? 0) * rates.eur
  }

  var isEmpty: Bool {
    amountRUB == nil && amountUSD == nil && amountEUR == nil
  }
}
