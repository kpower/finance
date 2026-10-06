import Foundation

/// RUB price of one unit of foreign currency.
struct Rates: Hashable, Sendable {
  var usd: Double
  var eur: Double
  var date: Date?
  /// `RateSource` identifier of where the rates came from.
  var source: String = ""

  static let zero = Rates(usd: 0, eur: 0, date: nil)
}
