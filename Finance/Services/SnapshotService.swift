import Foundation
import SwiftData

enum SnapshotService {
  /// Snapshots stored for `date`'s day (normally at most one).
  private static func snapshots(on date: Date, in context: ModelContext) throws -> [Snapshot] {
    let day = Calendar.current.startOfDay(for: date)
    let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: day)!
    return try context.fetch(
      FetchDescriptor<Snapshot>(predicate: #Predicate { $0.date >= day && $0.date < nextDay })
    )
  }

  /// Whether a snapshot other than `excluded` (nil: any snapshot) already occupies `date`'s day.
  static func isDayTaken(_ date: Date, excluding excluded: Snapshot?, in context: ModelContext) -> Bool {
    let others = (try? snapshots(on: date, in: context)) ?? []
    return others.contains { $0.persistentModelID != excluded?.persistentModelID }
  }
}
