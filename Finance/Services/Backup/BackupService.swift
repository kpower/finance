import Foundation
import SwiftData

/// Converts all stored data to a JSON backup and back.
enum BackupService {
  // MARK: Export

  static func makeBackup(from context: ModelContext) throws -> Backup {
    let snapshots = try context.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)]))
    return Backup(
      snapshots: snapshots.map {
        Backup.SnapshotEntry(
          date: $0.date, kind: $0.kind, usdRate: $0.usdRate, eurRate: $0.eurRate,
          ratesSource: $0.ratesSource, ratesRequestedFor: $0.ratesRequestedFor, items: $0.items,
          summaryRUB: $0.summaryRUB, summaryUSD: $0.summaryUSD, summaryEUR: $0.summaryEUR,
          comment: $0.comment.isEmpty ? nil : $0.comment
        )
      }
    )
  }

  static func encode(_ backup: Backup) throws -> Data {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    encoder.dateEncodingStrategy = .iso8601
    return try encoder.encode(backup)
  }

  // MARK: Import

  static func decode(_ data: Data) throws -> Backup {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let backup = try decoder.decode(Backup.self, from: data)
    guard backup.version <= Backup.currentVersion else { throw BackupError.unsupportedVersion(backup.version) }
    return backup
  }

  /// Replaces everything in the store with the backup's contents.
  static func restore(_ backup: Backup, into context: ModelContext) throws {
    try context.fetch(FetchDescriptor<Snapshot>()).forEach(context.delete)
    for entry in backup.snapshots {
      let rates = Rates(
        usd: entry.usdRate, eur: entry.eurRate, date: entry.ratesRequestedFor, source: entry.ratesSource)
      context.insert(Snapshot(
        date: entry.date, rates: rates, kind: entry.kind, items: entry.items,
        summaryRUB: entry.summaryRUB, summaryUSD: entry.summaryUSD, summaryEUR: entry.summaryEUR,
        comment: entry.comment ?? ""
      ))
    }
    try context.save()
  }
}
