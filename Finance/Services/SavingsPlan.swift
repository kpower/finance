import Foundation
import SwiftData

/// The savings calculation for a set of entries and year data, done the way the spreadsheet
/// this section replaces did it.
///
/// The earliest entry is the baseline: its spendable income (net minus expenses) is the "start money",
/// which then grows with official inflation. What an entry leaves above its start money is its delta.
/// A fixed share of the net income is saved no matter what; the delta less that share and less the
/// part left for a higher living standard is what to save per month on top.
struct SavingsPlan {
  private static let savedShare = 0.1
  /// The amount to save is rounded up to a multiple of this.
  private static let roundingStep = 1000.0

  private let baseline: SavingsInput
  private let years: [Int: SavingsYear]
  /// Percent by year.
  private let inflation: [Int: Double]

  /// Nil without entries: there is no baseline to compare with.
  init?(entries: [SavingsInput], years: [SavingsYear], inflation: [AnnualInflation]) {
    guard let baseline = entries.min(by: { $0.date < $1.date }) else { return nil }
    self.baseline = baseline
    self.years = Dictionary(years.map { ($0.year, $0) }, uniquingKeysWith: { first, _ in first })
    self.inflation = Dictionary(inflation.map { ($0.year, $0.percent) }, uniquingKeysWith: { first, _ in first })
  }

  /// Rows in ascending date order.
  static func rows(for entries: [SavingsEntry], years: [SavingsYear], inflation: [AnnualInflation]) -> [SavingsRow] {
    guard let plan = SavingsPlan(entries: entries.map(\.input), years: years, inflation: inflation) else { return [] }
    return entries.sorted { $0.date < $1.date }.map { entry in
      SavingsRow(
        id: entry.persistentModelID, date: entry.date, grossMonthly: entry.grossMonthly,
        expenses: entry.expenses, comment: entry.comment, outcome: plan.outcome(for: entry.input)
      )
    }
  }

  func outcome(for entry: SavingsInput) -> SavingsOutcome {
    do throws(SavingsGap) {
      return .figures(try figures(for: entry))
    } catch {
      return .missing(error)
    }
  }

  /// Nil for years before the baseline entry and when a year up to `year` lacks data.
  func startMoneyAtEnd(of year: Int) -> Double? {
    guard year >= baseline.date.year else { return nil }
    return try? startMoney(atEndOf: year)
  }

  // MARK: Figures

  private func parameters(for year: Int) throws(SavingsGap) -> SavingsYear {
    guard let parameters = years[year] else { throw .parameters(year: year) }
    return parameters
  }

  /// Inflation of the year as a fraction.
  private func inflation(of year: Int) throws(SavingsGap) -> Double {
    guard let percent = inflation[year] else { throw .inflation(year: year) }
    return percent / 100
  }

  private func figures(for entry: SavingsInput) throws(SavingsGap) -> SavingsFigures {
    let parameters = try parameters(for: entry.date.year)
    let net = Self.net(of: entry.grossMonthly, in: parameters)
    let startMoney = try startMoney(for: entry)
    let delta = net - entry.expensesTotal - startMoney
    let savedShare = net * Self.savedShare
    let lifeLevelUp = net * parameters.lifeLevelUp / 100
    let steps = ((delta - savedShare - lifeLevelUp) / Self.roundingStep).rounded(.up)
    return SavingsFigures(
      net: net, startMoney: startMoney, delta: delta, savedShare: savedShare,
      // Rounding up a small negative amount gives -0, which would be shown with a minus.
      saveMonthly: steps == 0 ? 0 : steps * Self.roundingStep
    )
  }

  /// Net of a monthly income. Every month is taxed on its own, with the yearly thresholds divided
  /// by 12, not by the income accumulated since the start of the year.
  private static func net(of grossMonthly: Double, in year: SavingsYear) -> Double {
    var remaining = grossMonthly
    var net = 0.0
    for bracket in year.higherTaxBrackets.sorted(by: { $0.threshold > $1.threshold }) {
      let taxed = max(remaining - bracket.threshold / 12, 0)
      net += taxed * (1 - bracket.rate / 100)
      remaining -= taxed
    }
    return net + remaining * (1 - year.baseTaxRate / 100)
  }

  // MARK: Start money

  private func baselineStartMoney() throws(SavingsGap) -> Double {
    try Self.net(of: baseline.grossMonthly, in: parameters(for: baseline.date.year)) - baseline.expensesTotal
  }

  /// Growth, as a fraction, from the inflation of the date's year accrued by the date's month.
  private func inflation(upToMonthOf date: Date) throws(SavingsGap) -> Double {
    try inflation(of: date.year) * Double(date.month) / 12
  }

  private func startMoney(atEndOf year: Int) throws(SavingsGap) -> Double {
    // The baseline year grows by the inflation accrued up to the baseline month,
    // not by what was left of the year.
    var value = try baselineStartMoney() * (1 + inflation(upToMonthOf: baseline.date))
    for laterYear in stride(from: baseline.date.year + 1, through: year, by: 1) {
      value *= 1 + (try inflation(of: laterYear))
    }
    return value
  }

  private func startMoney(for entry: SavingsInput) throws(SavingsGap) -> Double {
    if entry.date == baseline.date { return try baselineStartMoney() }
    let year = entry.date.year
    let previousYearEnd =
      if year == baseline.date.year { try baselineStartMoney() } else { try startMoney(atEndOf: year - 1) }
    return previousYearEnd * (1 + (try inflation(upToMonthOf: entry.date)))
  }
}

extension Date {
  fileprivate var year: Int { Calendar.current.component(.year, from: self) }
  fileprivate var month: Int { Calendar.current.component(.month, from: self) }
}
