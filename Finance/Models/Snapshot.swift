import Foundation
import SwiftData

/// State of all deposits and rates saved on a given day (section "История").
@Model
final class Snapshot {
  /// Start of the day the snapshot belongs to. One snapshot per day.
  var date: Date = Date.now
  var usdRate: Double = 0
  var eurRate: Double = 0
  var items: [DepositRecord] = []
  var createdAt: Date = Date.now

  init(date: Date, rates: Rates, items: [DepositRecord], createdAt: Date = .now) {
    self.date = Calendar.current.startOfDay(for: date)
    self.usdRate = rates.usd
    self.eurRate = rates.eur
    self.items = items
    self.createdAt = createdAt
  }

  var rates: Rates { Rates(usd: usdRate, eur: eurRate, date: date) }
}
