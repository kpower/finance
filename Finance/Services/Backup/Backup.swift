import Foundation

/// Backup file contents. Independent from the SwiftData models so the stored schema
/// can evolve without breaking old files; bump `currentVersion` on incompatible changes.
struct Backup: Codable {
  /// 5: history entries, the Savings section and inflation. Version 4 files load too, they have only
  /// history entries; so do version 3 files, their separate list of deposits is ignored.
  /// Older files do not load.
  static let currentVersion = 5

  var version = Backup.currentVersion
  var exportedAt = Date.now
  var snapshots: [SnapshotEntry]
  /// Absent in files written before the Savings section existed.
  var savings: Savings?
  /// Absent in files written before inflation was stored.
  var inflation: [Inflation]?

  struct SnapshotEntry: Codable {
    let date: Date
    let kind: Snapshot.Kind
    let usdRate: Double
    let eurRate: Double
    let ratesSource: RateSource
    let ratesRequestedFor: Date
    let items: [DepositRecord]
    let summaryRUB: Double
    let summaryUSD: Double
    let summaryEUR: Double
    /// Omitted when empty; absent in files written before comments existed.
    let comment: String?
  }

  struct Savings: Codable {
    let entries: [Entry]
    let years: [Year]

    struct Entry: Codable {
      let date: Date
      let grossMonthly: Double
      let expenses: [ExpenseBlock]
      /// Omitted when empty.
      let comment: String?
    }

    struct Year: Codable {
      let year: Int
      let lifeLevelUp: Double
      let baseTaxRate: Double
      let higherTaxBrackets: [TaxBracket]
    }
  }

  struct Inflation: Codable {
    let year: Int
    let percent: Double
  }
}
