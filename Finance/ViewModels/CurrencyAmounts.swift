import Foundation

/// Amounts in each of the currencies the app keeps.
struct CurrencyAmounts: Hashable, Sendable {
  var rub: Double
  var usd: Double
  var eur: Double

  func totalRUB(at rates: Rates) -> Double {
    rub + usd * rates.usd + eur * rates.eur
  }
}
