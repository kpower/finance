import Foundation

/// RUB price of one unit of foreign currency.
struct Rates: Hashable, Sendable {
  var usd: Double
  var eur: Double
  var date: Date?
  /// Where the rates came from, e.g. "ЦБ РФ (XML)" or `Rates.manualSource`.
  var source: String = ""

  static let zero = Rates(usd: 0, eur: 0, date: nil)
  static let manualSource = "Вручную"
}
