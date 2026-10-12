import Foundation
import SwiftData

/// One line of the history table: totals of a snapshot and change vs. the previous one.
struct HistoryRow: Identifiable {
  let id: PersistentIdentifier
  let date: Date
  let kind: Snapshot.Kind
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

  /// Calendar days since the previous snapshot; nil for the first one.
  let days: Int?
  let deltaRUB: HistoryDelta?
  let deltaUSD: HistoryDelta?
  let deltaEUR: HistoryDelta?

  let comment: String
}

/// Change of a total versus the previous snapshot.
struct HistoryDelta: Hashable {
  let value: Double
  let perDay: Double
}
