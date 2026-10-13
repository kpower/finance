import Foundation
import SwiftData

/// What the savings calculation needs to know about a calendar year, apart from its inflation.
@Model
final class SavingsYear {
  @Attribute(.unique) var year: Int
  /// Percent of the net income left for a higher living standard, on top of inflation.
  var lifeLevelUp: Double
  /// Income tax rate in percent for income below every threshold of `higherTaxBrackets`.
  var baseTaxRate: Double
  var higherTaxBrackets: [TaxBracket]

  init(year: Int, lifeLevelUp: Double, baseTaxRate: Double, higherTaxBrackets: [TaxBracket]) {
    self.year = year
    self.lifeLevelUp = lifeLevelUp
    self.baseTaxRate = baseTaxRate
    self.higherTaxBrackets = higherTaxBrackets
  }
}

/// A raised income tax rate for the part of income above a threshold.
struct TaxBracket: Codable, Hashable, Identifiable, Sendable {
  var id = UUID()
  /// Yearly income before tax the rate applies above.
  var threshold: Double
  /// Percent (15 means 15%).
  var rate: Double
}
