import Foundation
import SwiftData

/// Sample snapshots for previews.
enum PreviewData {
  static func seed(_ context: ModelContext) {
    let cal = Calendar.current
    func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: .now)! }
    func items(_ k: Double) -> [DepositRecord] {
      [
        DepositRecord(name: "Накопительный", bank: "Сбер", amountRUB: 500_000 * k, interestRate: 16, termMonths: 12, openDate: day(-200), closeDate: day(165)),
        DepositRecord(name: "Валютный", bank: "ВТБ", amountUSD: 3_000 * k, interestRate: 3.5, termMonths: 6, openDate: day(-90), closeDate: day(90)),
        DepositRecord(name: "Евро-вклад", bank: "Райффайзен", amountEUR: 2_000, interestRate: 2),
        DepositRecord(name: "Кошелёк", bank: "Тинькофф", amountRUB: 120_000, amountUSD: 500)
      ]
    }
    context.insert(Snapshot(
      date: day(-120), rates: Rates(usd: 88.0, eur: 95.5, date: nil, source: RateSource.manual),
      rub: 400_000, usd: 2_500, eur: 1_500))
    context.insert(Snapshot(date: day(-30), rates: Rates(usd: 90.5, eur: 98.2, date: nil), items: items(0.9)))
    context.insert(Snapshot(date: day(-14), rates: Rates(usd: 94.1, eur: 101.7, date: nil), items: items(1.0)))
    context.insert(Snapshot(date: day(-2), rates: Rates(usd: 92.0, eur: 104.3, date: nil), items: items(1.1)))
    try? context.save()
  }
}
