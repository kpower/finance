import Foundation
import SwiftData

enum HistoryCalculator {
  /// Rows in ascending date order, each compared with the previous snapshot.
  static func rows(for snapshots: [Snapshot]) -> [HistoryRow] {
    var result: [HistoryRow] = []
    for snapshot in snapshots.sorted(by: { $0.date < $1.date }) {
      result.append(makeRow(snapshot, after: result.last))
    }
    return result
  }

  private static func makeRow(_ s: Snapshot, after prev: HistoryRow?) -> HistoryRow {
    let usdInRUB = s.sumUSD * s.usdRate
    let eurInRUB = s.sumEUR * s.eurRate
    let total = s.sumRUB + usdInRUB + eurInRUB
    let totalUSD = s.usdRate == 0 ? nil : total / s.usdRate
    let totalEUR = s.eurRate == 0 ? nil : total / s.eurRate
    let days = prev
      .flatMap { Calendar.current.dateComponents([.day], from: $0.date, to: s.date).day }
      .flatMap { $0 > 0 ? $0 : nil }
    return HistoryRow(
      id: s.persistentModelID, date: s.date, kind: s.kind,
      ratesNeedAttention: s.ratesNeedAttention,
      sumRUB: s.sumRUB, sumUSD: s.sumUSD, usdRate: s.usdRate, usdInRUB: usdInRUB,
      sumEUR: s.sumEUR, eurRate: s.eurRate, eurInRUB: eurInRUB,
      totalRUB: total, totalUSD: totalUSD, totalEUR: totalEUR,
      days: days,
      deltaRUB: delta(from: prev?.totalRUB, to: total, days: days),
      deltaUSD: delta(from: prev?.totalUSD, to: totalUSD, days: days),
      deltaEUR: delta(from: prev?.totalEUR, to: totalEUR, days: days),
      comment: s.comment
    )
  }

  /// Nil when there is nothing to compare with.
  private static func delta(from old: Double?, to new: Double?, days: Int?) -> HistoryDelta? {
    guard let old, let new, let days else { return nil }
    let d = new - old
    return HistoryDelta(value: d, perDay: d / Double(days))
  }
}
