import Foundation
import SwiftData

/// A stored history entry: all deposits, or only their currency totals, and the rates on a given day.
@Model
final class Snapshot {
  /// Start of the day the snapshot belongs to: its key, one snapshot per day.
  @Attribute(.unique) var date: Date
  var usdRate: Double
  var eurRate: Double
  /// Stored identifier of where the rates came from.
  var ratesSource: String
  /// Start of the day the rates are for. Differs from `date` after the snapshot's date has been changed.
  var ratesRequestedFor: Date
  /// Stored identifier of what the snapshot holds: per-deposit details in `items` or the totals in `summary…`.
  var kind: String
  /// Empty for a snapshot that holds only totals.
  var items: [DepositRecord]
  /// Zero for a snapshot that holds per-deposit details.
  var summaryRUB: Double
  var summaryUSD: Double
  var summaryEUR: Double
  var comment: String

  init(
    date: Date,
    usdRate: Double,
    eurRate: Double,
    ratesSource: String,
    ratesRequestedFor: Date,
    kind: String,
    items: [DepositRecord],
    summaryRUB: Double,
    summaryUSD: Double,
    summaryEUR: Double,
    comment: String
  ) {
    self.date = date
    self.usdRate = usdRate
    self.eurRate = eurRate
    self.ratesSource = ratesSource
    self.ratesRequestedFor = ratesRequestedFor
    self.kind = kind
    self.items = items
    self.summaryRUB = summaryRUB
    self.summaryUSD = summaryUSD
    self.summaryEUR = summaryEUR
    self.comment = comment
  }
}

/// A deposit or account as it was on the day of a snapshot.
struct DepositRecord: Codable {
  let name: String
  let bank: String
  let amountRUB: Double?
  let amountUSD: Double?
  let amountEUR: Double?
  /// Annual interest rate in percent (18.5 means 18.5%). Nil for non-deposit accounts.
  let interestRate: Double?
  let termMonths: Int?
  let openDate: Date?
  let closeDate: Date?
}
