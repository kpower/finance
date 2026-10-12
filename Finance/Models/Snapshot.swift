import Foundation
import SwiftData

/// State of all deposits and rates saved on a given day (History section).
@Model
final class Snapshot {
  enum Kind: String, Codable, Sendable {
    /// Saved from the deposits table: per-deposit details in `items`.
    case detailed
    /// Archive entry entered by hand: only currency totals, no per-deposit details.
    case summaryOnly
  }

  /// Start of the day the snapshot belongs to: its key, one snapshot per day.
  @Attribute(.unique) var date: Date
  var usdRate: Double
  var eurRate: Double
  var ratesSource: RateSource
  /// Day the rates are for (`Rates.date`). Differs from `date` after the snapshot's date has been changed.
  var ratesRequestedFor: Date
  /// Per-deposit details of a `.detailed` snapshot; empty for `.summaryOnly`.
  var items: [DepositRecord]
  /// Stored as a raw value so existing stores migrate without a custom schema.
  private var kindRaw: String
  /// Totals of a `.summaryOnly` snapshot; unused for `.detailed`.
  var summaryRUB: Double
  var summaryUSD: Double
  var summaryEUR: Double
  var comment: String

  init(
    date: Date,
    rates: Rates,
    kind: Kind,
    items: [DepositRecord],
    summaryRUB: Double,
    summaryUSD: Double,
    summaryEUR: Double,
    comment: String
  ) {
    self.date = Calendar.current.startOfDay(for: date)
    self.usdRate = rates.usd
    self.eurRate = rates.eur
    self.ratesSource = rates.source
    self.ratesRequestedFor = Calendar.current.startOfDay(for: rates.date)
    self.items = items
    self.kindRaw = kind.rawValue
    self.summaryRUB = summaryRUB
    self.summaryUSD = summaryUSD
    self.summaryEUR = summaryEUR
    self.comment = comment
  }

  convenience init(date: Date, rates: Rates, items: [DepositRecord]) {
    self.init(
      date: date, rates: rates, kind: .detailed, items: items,
      summaryRUB: 0, summaryUSD: 0, summaryEUR: 0, comment: ""
    )
  }

  convenience init(date: Date, rates: Rates, rub: Double, usd: Double, eur: Double, comment: String) {
    self.init(
      date: date, rates: rates, kind: .summaryOnly, items: [],
      summaryRUB: rub, summaryUSD: usd, summaryEUR: eur, comment: comment
    )
  }

  var kind: Kind {
    get { Kind(rawValue: kindRaw) ?? .detailed }
    set { kindRaw = newValue.rawValue }
  }

  var rates: Rates {
    get { Rates(usd: usdRate, eur: eurRate, date: ratesRequestedFor, source: ratesSource) }
    set {
      usdRate = newValue.usd
      eurRate = newValue.eur
      ratesSource = newValue.source
      ratesRequestedFor = Calendar.current.startOfDay(for: newValue.date)
    }
  }

  // MARK: Totals

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

  var totalRUB: Double { sumRUB + sumUSD * usdRate + sumEUR * eurRate }

  var ratesNeedAttention: Bool { rates.needAttention(on: date) }

  /// Moves the snapshot to another day; its rates stay the ones of the day they were obtained for.
  func move(to newDate: Date) {
    date = Calendar.current.startOfDay(for: newDate)
  }
}
