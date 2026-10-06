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

  /// Start of the day the snapshot belongs to. One snapshot per day.
  var date: Date = Date.now
  var usdRate: Double = 0
  var eurRate: Double = 0
  /// `RateSource` identifier of where the rates came from.
  var ratesSource: String = ""
  /// Day the rates were obtained for; nil when typed by hand.
  /// Differs from `date` after the snapshot's date has been changed.
  var ratesRequestedFor: Date?
  var items: [DepositRecord] = []
  /// Stored as a raw value so existing stores migrate without a custom schema.
  private var kindRaw: String = Kind.detailed.rawValue
  /// Totals of a `.summaryOnly` snapshot; unused for `.detailed`.
  var summaryRUB: Double = 0
  var summaryUSD: Double = 0
  var summaryEUR: Double = 0
  var createdAt: Date = Date.now

  init(date: Date, rates: Rates, items: [DepositRecord], createdAt: Date = .now) {
    let day = Calendar.current.startOfDay(for: date)
    self.date = day
    self.usdRate = rates.usd
    self.eurRate = rates.eur
    self.ratesSource = rates.source
    self.ratesRequestedFor = RateSource.isManual(rates.source) ? nil : day
    self.items = items
    self.createdAt = createdAt
  }

  /// Archive entry with only currency totals.
  convenience init(date: Date, rates: Rates, rub: Double, usd: Double, eur: Double, createdAt: Date = .now) {
    self.init(date: date, rates: rates, items: [], createdAt: createdAt)
    kind = .summaryOnly
    summaryRUB = rub
    summaryUSD = usd
    summaryEUR = eur
  }

  var kind: Kind {
    get { Kind(rawValue: kindRaw) ?? .detailed }
    set { kindRaw = newValue.rawValue }
  }

  var rates: Rates { Rates(usd: usdRate, eur: eurRate, date: date, source: ratesSource) }

  // MARK: Totals

  var sumRUB: Double { kind == .summaryOnly ? summaryRUB : items.reduce(0) { $0 + ($1.amountRUB ?? 0) } }
  var sumUSD: Double { kind == .summaryOnly ? summaryUSD : items.reduce(0) { $0 + ($1.amountUSD ?? 0) } }
  var sumEUR: Double { kind == .summaryOnly ? summaryEUR : items.reduce(0) { $0 + ($1.amountEUR ?? 0) } }
  var totalRUB: Double { sumRUB + sumUSD * usdRate + sumEUR * eurRate }

  // MARK: Rates state

  /// Rates were typed by hand or obtained for another day than the snapshot's.
  var ratesNeedAttention: Bool {
    Self.ratesNeedAttention(source: ratesSource, requestedFor: ratesRequestedFor, date: date)
  }

  static func ratesNeedAttention(source: String, requestedFor: Date?, date: Date) -> Bool {
    if RateSource.isManual(source) { return true }
    // Entries saved before rate tracking existed: origin unknown, nothing to flag.
    guard let requestedFor else { return false }
    return !Calendar.current.isDate(requestedFor, inSameDayAs: date)
  }

  /// Moves the snapshot to another day, keeping track of which day its rates belong to.
  func move(to newDate: Date) {
    if ratesRequestedFor == nil, !RateSource.isManual(ratesSource) {
      ratesRequestedFor = date
    }
    date = Calendar.current.startOfDay(for: newDate)
  }

  func setRates(_ rates: Rates, requestedFor day: Date?) {
    usdRate = rates.usd
    eurRate = rates.eur
    ratesSource = rates.source
    ratesRequestedFor = day.map { Calendar.current.startOfDay(for: $0) }
  }
}
