import Foundation

/// Backup file contents. Independent from the SwiftData models so the stored schema
/// can evolve without breaking old files; bump `currentVersion` on incompatible changes.
struct Backup: Codable {
  /// 6: history entries, the Savings section and inflation. Version 5 files load too, the ids their
  /// deposits, expenses and tax brackets carry are ignored; so do version 4 files, they have only
  /// history entries, and version 3 files, their separate list of deposits is ignored.
  /// Older files do not load.
  static let currentVersion = 6

  var version = Backup.currentVersion
  var exportedAt = Date.now
  var snapshots: [SnapshotEntry]
  /// Absent in files written before the Savings section existed.
  var savings: Savings?
  /// Absent in files written before inflation was stored.
  var inflation: [Inflation]?

  struct SnapshotEntry: Codable {
    let date: Date
    /// `SnapshotKind.storedID`.
    let kind: String
    let usdRate: Double
    let eurRate: Double
    /// `RateSource.storedID`.
    let ratesSource: String
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
      let expenses: [ExpenseRecord]
      /// Omitted when empty.
      let comment: String?
    }

    struct Year: Codable {
      let year: Int
      let lifeLevelUp: Double
      let baseTaxRate: Double
      let higherTaxBrackets: [TaxBracketRecord]
    }
  }

  struct Inflation: Codable {
    let year: Int
    let percent: Double
  }
}
