import Foundation

/// Editable copy of a history entry: what the entry screen shows and compares with the saved values.
/// The entry itself changes only when the user saves.
struct SnapshotDraft: Equatable {
  /// Start of the entry's day.
  var date: Date
  /// Nil until entered: a new entry starts without rates.
  var rates: Rates?
  var content: SnapshotContent
  var comment: String
}

extension SnapshotDraft {
  init(_ values: SnapshotValues) {
    self.init(date: values.date, rates: values.rates, content: values.content, comment: values.comment)
  }

  /// A detailed entry for today that is not stored yet.
  static func newEntry(deposits: [Deposit]) -> SnapshotDraft {
    SnapshotDraft(
      date: Calendar.current.startOfDay(for: .now), rates: nil, content: .detailed(deposits), comment: "")
  }
}
