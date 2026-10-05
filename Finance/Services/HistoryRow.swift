import Foundation
import SwiftData

/// One line of the history table: totals of a snapshot and change vs. the previous one.
struct HistoryRow: Identifiable {
  /// Identifier of the snapshot this row was built from.
  var id: PersistentIdentifier
  var date: Date
  /// Archive entry with totals only, no per-deposit details.
  var isSummaryOnly: Bool
  /// Rates were typed by hand or obtained for another day.
  var ratesNeedAttention: Bool

  var sumRUB: Double
  var sumUSD: Double
  var usdRate: Double
  var usdInRUB: Double
  var sumEUR: Double
  var eurRate: Double
  var eurInRUB: Double

  var totalRUB: Double
  /// Nil when the rate is zero.
  var totalUSD: Double?
  var totalEUR: Double?

  /// Calendar days since the previous snapshot; nil for the first one.
  var days: Int?
  var deltaRUB: HistoryDelta?
  var deltaUSD: HistoryDelta?
  var deltaEUR: HistoryDelta?
}

/// Change of a total versus the previous snapshot.
struct HistoryDelta: Hashable {
  var value: Double
  var perDay: Double
}
