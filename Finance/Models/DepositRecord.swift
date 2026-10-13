import Foundation

/// A deposit or account as it was on the day of a history entry.
struct DepositRecord: Codable, Hashable, Identifiable, Sendable {
  /// Kept when a new entry is started from the deposits of an older one.
  var id = UUID()
  var name: String
  var bank: String
  var amountRUB: Double?
  var amountUSD: Double?
  var amountEUR: Double?
  /// Annual interest rate in percent (18.5 means 18.5%). Nil for non-deposit accounts.
  var interestRate: Double?
  var termMonths: Int?
  var openDate: Date?
  var closeDate: Date?
}

// MARK: - Amounts

extension DepositRecord {
  func totalRUB(at rates: Rates) -> Double {
    (amountRUB ?? 0) + (amountUSD ?? 0) * rates.usd + (amountEUR ?? 0) * rates.eur
  }

  var hasNoAmounts: Bool {
    amountRUB == nil && amountUSD == nil && amountEUR == nil
  }
}

// MARK: - Close date

extension DepositRecord {
  /// Deposits are usually paid out the day after the term ends.
  private static let closeDateExtraDays = 1

  /// Open date + term in months + `closeDateExtraDays`; nil if either input is missing.
  var expectedCloseDate: Date? {
    let calendar = Calendar.current
    guard let openDate, let termMonths, termMonths > 0,
      let termEnd = calendar.date(byAdding: .month, value: termMonths, to: calendar.startOfDay(for: openDate))
    else { return nil }
    return calendar.date(byAdding: .day, value: Self.closeDateExtraDays, to: termEnd)
  }

  /// Close date was entered by hand: it is set and differs from the one calculated from open date and term.
  var isCloseDateManual: Bool {
    guard let closeDate else { return false }
    guard let expectedCloseDate else { return true }
    return !Calendar.current.isDate(closeDate, inSameDayAs: expectedCloseDate)
  }

  /// Changes open date and/or term, recalculating the close date unless it was entered by hand.
  mutating func updateTerm(openDate: Date?, termMonths: Int?) {
    let isAuto = !isCloseDateManual
    self.openDate = openDate
    self.termMonths = termMonths
    if isAuto {
      closeDate = expectedCloseDate
    }
  }

  mutating func recalculateCloseDate() {
    closeDate = expectedCloseDate
  }
}
