import Foundation

/// Backup file contents. Independent from the SwiftData models so the stored schema
/// can evolve without breaking old files; bump `currentVersion` on incompatible changes.
struct Backup: Codable {
  /// 4: history entries only. Version 3 files load too, their separate list of deposits is ignored.
  /// Older files do not load.
  static let currentVersion = 4

  var version = Backup.currentVersion
  var exportedAt = Date.now
  var snapshots: [SnapshotEntry]

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
}
