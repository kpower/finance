import Foundation
import SwiftData

/// One line of the history table: totals of an entry and change vs. the previous one.
struct HistoryRow: Identifiable {
  let id: PersistentIdentifier
  let date: Date
  let kind: SnapshotKind
  let ratesNeedAttention: Bool

  let sumRUB: Double
  let sumUSD: Double
  let usdRate: Double
  let usdInRUB: Double
  let sumEUR: Double
  let eurRate: Double
  let eurInRUB: Double

  let totalRUB: Double
  /// Nil when the rate is zero.
  let totalUSD: Double?
  let totalEUR: Double?

  /// Calendar days since the previous entry; nil for the first one.
  let days: Int?
  let deltaRUB: HistoryDelta?
  let deltaUSD: HistoryDelta?
  let deltaEUR: HistoryDelta?

  let comment: String
}

/// Change of a total versus the previous entry.
struct HistoryDelta: Hashable {
  let value: Double
  let perDay: Double
}
