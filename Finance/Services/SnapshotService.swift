import Foundation
import SwiftData

enum SnapshotService {
  /// Saves the current deposits and rates as the snapshot for `date`'s day,
  /// replacing an existing snapshot for that day.
  @discardableResult
  static func capture(
    deposits: [Deposit],
    rates: Rates,
    on date: Date = .now,
    in context: ModelContext
  ) throws -> Snapshot {
    let day = Calendar.current.startOfDay(for: date)
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day)!
    let existing = try context.fetch(
      FetchDescriptor<Snapshot>(predicate: #Predicate { $0.date >= day && $0.date < nextDay })
    )
    existing.forEach(context.delete)

    let items = deposits
      .sorted { $0.createdAt < $1.createdAt }
      .map(\.record)
    let snapshot = Snapshot(date: day, rates: rates, items: items)
    context.insert(snapshot)
    try context.save()
    return snapshot
  }
}
