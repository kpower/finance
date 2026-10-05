import Foundation
import SwiftData

enum HistoryCalculator {
  /// Rows in ascending date order, each compared with the previous snapshot.
  static func rows(for snapshots: [Snapshot], calendar: Calendar = .current) -> [HistoryRow] {
    var result: [HistoryRow] = []
    for snapshot in snapshots.sorted(by: { $0.date < $1.date }) {
      var row = makeRow(snapshot)
      if let prev = result.last,
        let days = calendar.dateComponents([.day], from: prev.date, to: row.date).day, days > 0
      {
        row.days = days
        row.deltaRUB = delta(from: prev.totalRUB, to: row.totalRUB, days: days)
        row.deltaUSD = delta(from: prev.totalUSD, to: row.totalUSD, days: days)
        row.deltaEUR = delta(from: prev.totalEUR, to: row.totalEUR, days: days)
      }
      result.append(row)
    }
    return result
  }

  private static func makeRow(_ s: Snapshot) -> HistoryRow {
    let sumRUB = s.items.reduce(0) { $0 + ($1.amountRUB ?? 0) }
    let sumUSD = s.items.reduce(0) { $0 + ($1.amountUSD ?? 0) }
    let sumEUR = s.items.reduce(0) { $0 + ($1.amountEUR ?? 0) }
    let usdInRUB = sumUSD * s.usdRate
    let eurInRUB = sumEUR * s.eurRate
    let total = sumRUB + usdInRUB + eurInRUB
    return HistoryRow(
      id: s.persistentModelID, date: s.date,
      sumRUB: sumRUB, sumUSD: sumUSD, usdRate: s.usdRate, usdInRUB: usdInRUB,
      sumEUR: sumEUR, eurRate: s.eurRate, eurInRUB: eurInRUB,
      totalRUB: total,
      totalUSD: s.usdRate == 0 ? nil : total / s.usdRate,
      totalEUR: s.eurRate == 0 ? nil : total / s.eurRate
    )
  }

  private static func delta(from old: Double, to new: Double, days: Int) -> HistoryDelta {
    let d = new - old
    return HistoryDelta(value: d, perDay: d / Double(days))
  }

  private static func delta(from old: Double?, to new: Double?, days: Int) -> HistoryDelta? {
    guard let old, let new else { return nil }
    return delta(from: old, to: new, days: days)
  }
}
