import Foundation

/// Backup file contents. Independent from the SwiftData models so the stored schema
/// can evolve without breaking old files; bump `currentVersion` on incompatible changes.
struct Backup: Codable {
  /// 3: every snapshot states the source and the day of its rates. Older files do not load.
  static let currentVersion = 3

  var version = Backup.currentVersion
  var exportedAt = Date.now
  var deposits: [DepositEntry]
  var snapshots: [SnapshotEntry]

  struct DepositEntry: Codable {
    let name: String
    let bank: String
    let amountRUB: Double?
    let amountUSD: Double?
    let amountEUR: Double?
    let interestRate: Double?
    let termMonths: Int?
    let openDate: Date?
    let closeDate: Date?
    let createdAt: Date
  }

  struct SnapshotEntry: Codable {
    let date: Date
    let kind: Snapshot.Kind
    let usdRate: Double
    let eurRate: Double
    let ratesSource: RateSource
    let ratesRequestedFor: Date
    /// Per-deposit details of a `.detailed` snapshot.
    let items: [DepositRecord]
    /// Totals of a `.summaryOnly` snapshot.
    let summaryRUB: Double
    let summaryUSD: Double
    let summaryEUR: Double
    /// Omitted when empty; absent in files written before comments existed.
    let comment: String?
  }
}
