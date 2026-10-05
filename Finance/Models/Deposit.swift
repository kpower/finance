import Foundation
import SwiftData

/// A live, editable deposit or account (section "Вклады").
@Model
final class Deposit: DepositAmounts {
  var name: String = ""
  var bank: String = ""
  var amountRUB: Double?
  var amountUSD: Double?
  var amountEUR: Double?
  /// Annual interest rate in percent (18.5 means 18.5%). Nil for non-deposit accounts.
  var interestRate: Double?
  var termMonths: Int?
  var openDate: Date?
  var closeDate: Date?
  var createdAt: Date = Date.now

  init(
    name: String = "",
    bank: String = "",
    amountRUB: Double? = nil,
    amountUSD: Double? = nil,
    amountEUR: Double? = nil,
    interestRate: Double? = nil,
    termMonths: Int? = nil,
    openDate: Date? = nil,
    closeDate: Date? = nil,
    createdAt: Date = .now
  ) {
    self.name = name
    self.bank = bank
    self.amountRUB = amountRUB
    self.amountUSD = amountUSD
    self.amountEUR = amountEUR
    self.interestRate = interestRate
    self.termMonths = termMonths
    self.openDate = openDate
    self.closeDate = closeDate
    self.createdAt = createdAt
  }

  /// Frozen value copy for storing in a snapshot.
  var record: DepositRecord {
    DepositRecord(
      name: name, bank: bank,
      amountRUB: amountRUB, amountUSD: amountUSD, amountEUR: amountEUR,
      interestRate: interestRate, termMonths: termMonths,
      openDate: openDate, closeDate: closeDate
    )
  }
}

// MARK: - Close date

extension Deposit {
  /// Deposits are usually paid out the day after the term ends.
  static let closeDateExtraDays = 1

  /// Open date + term in months + `closeDateExtraDays`; nil if either input is missing.
  static func expectedCloseDate(openDate: Date?, termMonths: Int?, calendar: Calendar = .current) -> Date? {
    guard let openDate, let termMonths, termMonths > 0,
      let termEnd = calendar.date(byAdding: .month, value: termMonths, to: calendar.startOfDay(for: openDate))
    else { return nil }
    return calendar.date(byAdding: .day, value: closeDateExtraDays, to: termEnd)
  }

  var expectedCloseDate: Date? {
    Self.expectedCloseDate(openDate: openDate, termMonths: termMonths)
  }

  /// Close date was entered by hand: it is set and differs from the one calculated from open date and term.
  var isCloseDateManual: Bool {
    guard let closeDate else { return false }
    guard let expected = expectedCloseDate else { return true }
    return !Calendar.current.isDate(closeDate, inSameDayAs: expected)
  }

  /// Changes open date and/or term, recalculating the close date unless it was entered by hand.
  func updateTerm(openDate: Date?, termMonths: Int?) {
    let isAuto = !isCloseDateManual
    self.openDate = openDate
    self.termMonths = termMonths
    if isAuto {
      closeDate = expectedCloseDate
    }
  }

  /// Discards a manually entered close date in favor of the calculated one.
  func recalculateCloseDate() {
    closeDate = expectedCloseDate
  }
}
