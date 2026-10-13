import Foundation

/// RUB price of one unit of foreign currency on a given day, and where it came from.
/// Always complete: rates that are not entered yet are a missing value (`Rates?`) in view state.
struct Rates: Hashable, Sendable {
  let usd: Double
  let eur: Double
  /// Day the rates are for: the day they were fetched for, or the day they were typed in for.
  let date: Date
  let source: RateSource

  /// Typed by hand or obtained for another day than `day`.
  func needAttention(on day: Date) -> Bool {
    switch source {
    case .manual: true
    case .cbrXML, .cbrJSON: !Calendar.current.isDate(date, inSameDayAs: day)
    }
  }
}
