import Foundation
import SwiftData

enum PreviewData {
  static func seed(_ context: ModelContext) {
    let cal = Calendar.current
    func day(_ offset: Int) -> Date { cal.date(byAdding: .day, value: offset, to: .now)! }
    func deposits(_ k: Double) -> [Deposit] {
      [
        Deposit(
          name: "Накопительный", bank: "Сбер", amountRUB: 500_000 * k, amountUSD: nil, amountEUR: nil,
          interestRate: 16, termMonths: 12, openDate: day(-200), closeDate: day(165)),
        Deposit(
          name: "Валютный", bank: "ВТБ", amountRUB: nil, amountUSD: 3_000 * k, amountEUR: nil,
          interestRate: 3.5, termMonths: 6, openDate: day(-90), closeDate: day(90)),
        Deposit(
          name: "Евро-вклад", bank: "Райффайзен", amountRUB: nil, amountUSD: nil, amountEUR: 2_000,
          interestRate: 2, termMonths: nil, openDate: nil, closeDate: nil),
        Deposit(
          name: "Кошелёк", bank: "Тинькофф", amountRUB: 120_000, amountUSD: 500, amountEUR: nil,
          interestRate: nil, termMonths: nil, openDate: nil, closeDate: nil)
      ]
    }
    func snapshot(_ offset: Int, usd: Double, eur: Double, source: RateSource, _ content: SnapshotContent) -> Snapshot {
      Snapshot(SnapshotValues(
        date: day(offset), rates: Rates(usd: usd, eur: eur, date: day(offset), source: source),
        content: content, comment: ""))
    }
    context.insert(snapshot(
      -120, usd: 88.0, eur: 95.5, source: .manual,
      .summaryOnly(CurrencyAmounts(rub: 400_000, usd: 2_500, eur: 1_500))))
    context.insert(snapshot(-30, usd: 90.5, eur: 98.2, source: .cbrXML, .detailed(deposits(0.9))))
    context.insert(snapshot(-14, usd: 94.1, eur: 101.7, source: .cbrXML, .detailed(deposits(1.0))))
    context.insert(snapshot(-2, usd: 92.0, eur: 104.3, source: .cbrXML, .detailed(deposits(1.1))))
    for year in 2024...cal.component(.year, from: .now) {
      context.insert(AnnualInflation(AnnualInflationValues(year: year, percent: 7.5)))
      context.insert(SavingsYear(SavingsYearValues(
        year: year, lifeLevelUp: 5, baseTaxRate: 13,
        higherTaxBrackets: [TaxBracket(threshold: 2_400_000, rate: 15), TaxBracket(threshold: 5_000_000, rate: 18)])))
    }
    context.insert(SavingsEntry(SavingsEntryValues(
      date: cal.date(from: DateComponents(year: 2024, month: 3, day: 1))!, grossMonthly: 250_000,
      expenses: [ExpenseBlock(name: "Аренда", content: .single(amount: 60_000))], comment: "ревью")))
    context.insert(SavingsEntry(SavingsEntryValues(
      date: day(-40), grossMonthly: 420_000, expenses: expenses, comment: "ипотека")))
    try? context.save()
  }

  static let expenses = [
    ExpenseBlock(name: "Страховка", content: .single(amount: 4_000)),
    ExpenseBlock(
      name: "Ипотека",
      content: .split(parts: [ExpensePart(name: "тело", amount: 78_000), ExpensePart(name: "проценты", amount: 18_000)]))
  ]
}
