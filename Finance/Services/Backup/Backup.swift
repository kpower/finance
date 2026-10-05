import Foundation

/// Backup file contents. Independent from the SwiftData models so the stored schema
/// can evolve without breaking old files; bump `currentVersion` on incompatible changes.
struct Backup: Codable {
  static let currentVersion = 1

  var version = Backup.currentVersion
  var exportedAt = Date.now
  var deposits: [DepositEntry]
  var rates: [RateEntry]
  var snapshots: [SnapshotEntry]

  struct DepositEntry: Codable {
    var name: String
    var bank: String
    var amountRUB: Double?
    var amountUSD: Double?
    var amountEUR: Double?
    var interestRate: Double?
    var termMonths: Int?
    var openDate: Date?
    var closeDate: Date?
    var createdAt: Date
  }

  struct RateEntry: Codable {
    var rateDate: Date
    var usd: Double
    var eur: Double
    var source: String
    var createdAt: Date
  }

  struct SnapshotEntry: Codable {
    var date: Date
    var kind: Snapshot.Kind
    var usdRate: Double
    var eurRate: Double
    var ratesSource: String
    var ratesRequestedFor: Date?
    /// Per-deposit details of a `.detailed` snapshot.
    var items: [DepositRecord]
    /// Totals of a `.summaryOnly` snapshot.
    var summaryRUB: Double
    var summaryUSD: Double
    var summaryEUR: Double
    var createdAt: Date
  }
}
