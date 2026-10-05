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
    try snapshots(on: date, in: context).forEach(context.delete)
    let items = deposits
      .sorted { $0.createdAt < $1.createdAt }
      .map(\.record)
    let snapshot = Snapshot(date: date, rates: rates, items: items)
    context.insert(snapshot)
    try context.save()
    return snapshot
  }

  /// Snapshots stored for `date`'s day (normally at most one).
  static func snapshots(on date: Date, in context: ModelContext) throws -> [Snapshot] {
    let day = Calendar.current.startOfDay(for: date)
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day)!
    return try context.fetch(
      FetchDescriptor<Snapshot>(predicate: #Predicate { $0.date >= day && $0.date < nextDay })
    )
  }

  /// Whether a snapshot other than `excluded` already occupies `date`'s day.
  static func isDayTaken(_ date: Date, excluding excluded: Snapshot? = nil, in context: ModelContext) -> Bool {
    let others = (try? snapshots(on: date, in: context)) ?? []
    return others.contains { $0.persistentModelID != excluded?.persistentModelID }
  }
}
