import Foundation

enum HistoryCalculator {
  /// Rows in ascending date order, each compared with the previous entry.
  static func rows(for entries: [Stored<SnapshotValues>]) -> [HistoryRow] {
    var result: [HistoryRow] = []
    for entry in entries.sorted(by: { $0.values.date < $1.values.date }) {
      result.append(makeRow(entry, after: result.last))
    }
    return result
  }

  private static func makeRow(_ entry: Stored<SnapshotValues>, after prev: HistoryRow?) -> HistoryRow {
    let date = entry.values.date
    let rates = entry.values.rates
    let sums = entry.values.content.sums
    let usdInRUB = sums.usd * rates.usd
    let eurInRUB = sums.eur * rates.eur
    let total = sums.totalRUB(at: rates)
    let totalUSD = rates.usd == 0 ? nil : total / rates.usd
    let totalEUR = rates.eur == 0 ? nil : total / rates.eur
    let days = prev
      .flatMap { Calendar.current.dateComponents([.day], from: $0.date, to: date).day }
      .flatMap { $0 > 0 ? $0 : nil }
    return HistoryRow(
      id: entry.id, date: date, kind: entry.values.content.kind,
      ratesNeedAttention: rates.needAttention(on: date),
      sumRUB: sums.rub, sumUSD: sums.usd, usdRate: rates.usd, usdInRUB: usdInRUB,
      sumEUR: sums.eur, eurRate: rates.eur, eurInRUB: eurInRUB,
      totalRUB: total, totalUSD: totalUSD, totalEUR: totalEUR,
      days: days,
      deltaRUB: delta(from: prev?.totalRUB, to: total, days: days),
      deltaUSD: delta(from: prev?.totalUSD, to: totalUSD, days: days),
      deltaEUR: delta(from: prev?.totalEUR, to: totalEUR, days: days),
      comment: entry.values.comment
    )
  }

  /// Nil when there is nothing to compare with.
  private static func delta(from old: Double?, to new: Double?, days: Int?) -> HistoryDelta? {
    guard let old, let new, let days else { return nil }
    let d = new - old
    return HistoryDelta(value: d, perDay: d / Double(days))
  }
}
