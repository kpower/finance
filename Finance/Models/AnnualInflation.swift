import Foundation
import SwiftData

/// Official inflation of a calendar year: December against December of the year before.
@Model
final class AnnualInflation {
  @Attribute(.unique) var year: Int
  /// 7.42 means 7.42%.
  var percent: Double

  init(year: Int, percent: Double) {
    self.year = year
    self.percent = percent
  }
}
