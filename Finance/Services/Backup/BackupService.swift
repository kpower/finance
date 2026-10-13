import Foundation
import SwiftData

/// Converts all stored data to a JSON backup and back.
enum BackupService {
  // MARK: Export

  static func makeBackup(from context: ModelContext) throws -> Backup {
    let snapshots = try context.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)]))
    let savingsEntries = try context.fetch(FetchDescriptor<SavingsEntry>(sortBy: [SortDescriptor(\.date)]))
    let savingsYears = try context.fetch(FetchDescriptor<SavingsYear>(sortBy: [SortDescriptor(\.year)]))
    let inflation = try context.fetch(FetchDescriptor<AnnualInflation>(sortBy: [SortDescriptor(\.year)]))
    return Backup(
      snapshots: snapshots.map {
        Backup.SnapshotEntry(
          date: $0.date, kind: $0.kind, usdRate: $0.usdRate, eurRate: $0.eurRate,
          ratesSource: $0.ratesSource, ratesRequestedFor: $0.ratesRequestedFor, items: $0.items,
          summaryRUB: $0.summaryRUB, summaryUSD: $0.summaryUSD, summaryEUR: $0.summaryEUR,
          comment: $0.comment.isEmpty ? nil : $0.comment
        )
      },
      savings: Backup.Savings(
        entries: savingsEntries.map {
          Backup.Savings.Entry(
            date: $0.date, grossMonthly: $0.grossMonthly, expenses: $0.expenses,
            comment: $0.comment.isEmpty ? nil : $0.comment
          )
        },
        years: savingsYears.map {
          Backup.Savings.Year(
            year: $0.year, lifeLevelUp: $0.lifeLevelUp,
            baseTaxRate: $0.baseTaxRate, higherTaxBrackets: $0.higherTaxBrackets
          )
        }
      ),
      inflation: inflation.map { Backup.Inflation(year: $0.year, percent: $0.percent) }
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
    // The store takes both identifiers as they are, and one it does not know cannot be read back.
    let areIdentifiersKnown = backup.snapshots.allSatisfy {
      SnapshotKind(storedID: $0.kind) != nil && RateSource(storedID: $0.ratesSource) != nil
    }
    guard areIdentifiersKnown else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: [], debugDescription: "Unknown kind or rate source of a history entry"))
    }
    return backup
  }

  /// Replaces everything in the store with the backup's contents.
  static func restore(_ backup: Backup, into context: ModelContext) throws {
    try context.fetch(FetchDescriptor<Snapshot>()).forEach(context.delete)
    try context.fetch(FetchDescriptor<SavingsEntry>()).forEach(context.delete)
    try context.fetch(FetchDescriptor<SavingsYear>()).forEach(context.delete)
    try context.fetch(FetchDescriptor<AnnualInflation>()).forEach(context.delete)
    for entry in backup.snapshots {
      context.insert(Snapshot(
        date: day(of: entry.date), usdRate: entry.usdRate, eurRate: entry.eurRate,
        ratesSource: entry.ratesSource, ratesRequestedFor: day(of: entry.ratesRequestedFor),
        kind: entry.kind, items: entry.items,
        summaryRUB: entry.summaryRUB, summaryUSD: entry.summaryUSD, summaryEUR: entry.summaryEUR,
        comment: entry.comment ?? ""
      ))
    }
    if let savings = backup.savings {
      for entry in savings.entries {
        context.insert(SavingsEntry(
          date: day(of: entry.date), grossMonthly: entry.grossMonthly, expenses: entry.expenses,
          comment: entry.comment ?? ""
        ))
      }
      for year in savings.years {
        context.insert(SavingsYear(
          year: year.year, lifeLevelUp: year.lifeLevelUp,
          baseTaxRate: year.baseTaxRate, higherTaxBrackets: year.higherTaxBrackets
        ))
      }
    }
    for year in backup.inflation ?? [] {
      context.insert(AnnualInflation(year: year.year, percent: year.percent))
    }
    try context.save()
  }

  /// Entries are stored under the start of their day here, which a file written in another
  /// time zone does not hold.
  private static func day(of date: Date) -> Date {
    Calendar.current.startOfDay(for: date)
  }
}
