import Foundation
import SwiftData

// MARK: - Reading

extension SnapshotValues {
  init(_ snapshot: Snapshot) {
    guard let source = RateSource(storedID: snapshot.ratesSource), let kind = SnapshotKind(storedID: snapshot.kind)
    else {
      // Both are written from `storedID` only, and a backup with anything else in them is not loaded.
      fatalError("Unknown rate source or kind of a stored snapshot: \(snapshot.ratesSource), \(snapshot.kind)")
    }
    let content: SnapshotContent =
      switch kind {
      case .detailed:
        .detailed(snapshot.items.map { Deposit($0) })
      case .summaryOnly:
        .summaryOnly(CurrencyAmounts(rub: snapshot.summaryRUB, usd: snapshot.summaryUSD, eur: snapshot.summaryEUR))
      }
    self.init(
      date: snapshot.date,
      rates: Rates(usd: snapshot.usdRate, eur: snapshot.eurRate, date: snapshot.ratesRequestedFor, source: source),
      content: content,
      comment: snapshot.comment
    )
  }
}

extension Stored<SnapshotValues> {
  init(_ snapshot: Snapshot) {
    self.init(id: snapshot.persistentModelID, values: SnapshotValues(snapshot))
  }
}

extension Deposit {
  fileprivate init(_ record: DepositRecord) {
    self.init(
      name: record.name, bank: record.bank,
      amountRUB: record.amountRUB, amountUSD: record.amountUSD, amountEUR: record.amountEUR,
      interestRate: record.interestRate, termMonths: record.termMonths,
      openDate: record.openDate, closeDate: record.closeDate
    )
  }
}

// MARK: - Writing

extension Snapshot {
  convenience init(_ values: SnapshotValues) {
    let content = values.content.stored
    self.init(
      date: Calendar.current.startOfDay(for: values.date),
      usdRate: values.rates.usd,
      eurRate: values.rates.eur,
      ratesSource: values.rates.source.storedID,
      ratesRequestedFor: Calendar.current.startOfDay(for: values.rates.date),
      kind: values.content.kind.storedID,
      items: content.items,
      summaryRUB: content.summary.rub,
      summaryUSD: content.summary.usd,
      summaryEUR: content.summary.eur,
      comment: values.comment
    )
  }

  func update(from values: SnapshotValues) {
    let content = values.content.stored
    date = Calendar.current.startOfDay(for: values.date)
    usdRate = values.rates.usd
    eurRate = values.rates.eur
    ratesSource = values.rates.source.storedID
    ratesRequestedFor = Calendar.current.startOfDay(for: values.rates.date)
    kind = values.content.kind.storedID
    items = content.items
    summaryRUB = content.summary.rub
    summaryUSD = content.summary.usd
    summaryEUR = content.summary.eur
    comment = values.comment
  }
}

extension SnapshotContent {
  /// The stored fields; the ones the kind does not use are empty or zero.
  fileprivate var stored: (items: [DepositRecord], summary: CurrencyAmounts) {
    switch self {
    case let .detailed(deposits): (deposits.map { DepositRecord($0) }, CurrencyAmounts(rub: 0, usd: 0, eur: 0))
    case let .summaryOnly(totals): ([], totals)
    }
  }
}

extension DepositRecord {
  fileprivate init(_ deposit: Deposit) {
    self.init(
      name: deposit.name, bank: deposit.bank,
      amountRUB: deposit.amountRUB, amountUSD: deposit.amountUSD, amountEUR: deposit.amountEUR,
      interestRate: deposit.interestRate, termMonths: deposit.termMonths,
      openDate: deposit.openDate, closeDate: deposit.closeDate
    )
  }
}
