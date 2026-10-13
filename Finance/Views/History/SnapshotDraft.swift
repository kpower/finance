import Foundation

/// Editable copy of a history entry: what the entry screen shows and compares with the saved values.
/// The entry itself changes only when the user saves.
struct SnapshotDraft: Equatable, SnapshotAmounts {
  let kind: Snapshot.Kind
  /// Start of the entry's day.
  var date: Date
  /// Nil until entered: a new entry starts without rates.
  var rates: Rates?
  var comment: String
  /// Deposits of a `.detailed` entry; empty for `.summaryOnly`.
  var items: [DepositRecord]
  /// Totals of a `.summaryOnly` entry; unused for `.detailed`.
  var summaryRUB: Double
  var summaryUSD: Double
  var summaryEUR: Double
}

extension SnapshotDraft {
  init(_ snapshot: Snapshot) {
    self.init(
      kind: snapshot.kind, date: snapshot.date, rates: snapshot.rates, comment: snapshot.comment,
      items: snapshot.items,
      summaryRUB: snapshot.summaryRUB, summaryUSD: snapshot.summaryUSD, summaryEUR: snapshot.summaryEUR
    )
  }

  /// A detailed entry for today that is not stored yet.
  static func newEntry(items: [DepositRecord]) -> SnapshotDraft {
    SnapshotDraft(
      kind: .detailed, date: Calendar.current.startOfDay(for: .now), rates: nil, comment: "",
      items: items, summaryRUB: 0, summaryUSD: 0, summaryEUR: 0
    )
  }
}
