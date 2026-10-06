import Foundation
import SwiftData

/// A set of exchange rates the user applied (fetched from a source or typed in).
/// The most recently created record is the one in effect.
@Model
final class RateRecord {
  /// Date the rates are valid for (as reported by the source).
  var rateDate: Date = Date.now
  var usd: Double = 0
  var eur: Double = 0
  /// `RateSource` identifier of where the rates came from.
  var source: String = ""
  var createdAt: Date = Date.now

  init(rateDate: Date, usd: Double, eur: Double, source: String, createdAt: Date = .now) {
    self.rateDate = rateDate
    self.usd = usd
    self.eur = eur
    self.source = source
    self.createdAt = createdAt
  }

  var rates: Rates { Rates(usd: usd, eur: eur, date: rateDate, source: source) }
}

extension Array where Element == RateRecord {
  /// Rates in effect: the latest created record. Expects nothing about ordering.
  var current: Rates {
    self.max(by: { $0.createdAt < $1.createdAt })?.rates ?? .zero
  }
}
