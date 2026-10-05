import Foundation
import SwiftData

/// Converts all stored data to a JSON backup and back.
enum BackupService {
  enum Failure: LocalizedError {
    case unreadable(String)
    case unsupportedVersion(Int)

    var errorDescription: String? {
      switch self {
      case .unreadable(let reason): "Файл не похож на бэкап Finance: \(reason)"
      case .unsupportedVersion(let version): "Бэкап версии \(version) создан более новой версией приложения."
      }
    }
  }

  // MARK: Export

  static func makeBackup(from context: ModelContext) throws -> Backup {
    let deposits = try context.fetch(FetchDescriptor<Deposit>(sortBy: [SortDescriptor(\.createdAt)]))
    let rates = try context.fetch(FetchDescriptor<RateRecord>(sortBy: [SortDescriptor(\.createdAt)]))
    let snapshots = try context.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)]))
    return Backup(
      deposits: deposits.map {
        Backup.DepositEntry(
          name: $0.name, bank: $0.bank,
          amountRUB: $0.amountRUB, amountUSD: $0.amountUSD, amountEUR: $0.amountEUR,
          interestRate: $0.interestRate, termMonths: $0.termMonths,
          openDate: $0.openDate, closeDate: $0.closeDate, createdAt: $0.createdAt
        )
      },
      rates: rates.map {
        Backup.RateEntry(rateDate: $0.rateDate, usd: $0.usd, eur: $0.eur, source: $0.source, createdAt: $0.createdAt)
      },
      snapshots: snapshots.map {
        Backup.SnapshotEntry(
          date: $0.date, kind: $0.kind, usdRate: $0.usdRate, eurRate: $0.eurRate,
          ratesSource: $0.ratesSource, ratesRequestedFor: $0.ratesRequestedFor, items: $0.items,
          summaryRUB: $0.summaryRUB, summaryUSD: $0.summaryUSD, summaryEUR: $0.summaryEUR,
          createdAt: $0.createdAt
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
    let backup: Backup
    do {
      backup = try decoder.decode(Backup.self, from: data)
    } catch {
      throw Failure.unreadable(error.localizedDescription)
    }
    guard backup.version <= Backup.currentVersion else { throw Failure.unsupportedVersion(backup.version) }
    return backup
  }

  /// Replaces everything in the store with the backup's contents.
  static func restore(_ backup: Backup, into context: ModelContext) throws {
    try context.fetch(FetchDescriptor<Deposit>()).forEach(context.delete)
    try context.fetch(FetchDescriptor<RateRecord>()).forEach(context.delete)
    try context.fetch(FetchDescriptor<Snapshot>()).forEach(context.delete)

    for entry in backup.deposits {
      context.insert(Deposit(
        name: entry.name, bank: entry.bank,
        amountRUB: entry.amountRUB, amountUSD: entry.amountUSD, amountEUR: entry.amountEUR,
        interestRate: entry.interestRate, termMonths: entry.termMonths,
        openDate: entry.openDate, closeDate: entry.closeDate, createdAt: entry.createdAt
      ))
    }
    for entry in backup.rates {
      context.insert(RateRecord(
        rateDate: entry.rateDate, usd: entry.usd, eur: entry.eur, source: entry.source, createdAt: entry.createdAt
      ))
    }
    for entry in backup.snapshots {
      let rates = Rates(usd: entry.usdRate, eur: entry.eurRate, date: entry.date, source: entry.ratesSource)
      let snapshot = Snapshot(date: entry.date, rates: rates, items: entry.items, createdAt: entry.createdAt)
      snapshot.kind = entry.kind
      snapshot.summaryRUB = entry.summaryRUB
      snapshot.summaryUSD = entry.summaryUSD
      snapshot.summaryEUR = entry.summaryEUR
      snapshot.ratesRequestedFor = entry.ratesRequestedFor
      context.insert(snapshot)
    }
    try context.save()
  }
}
