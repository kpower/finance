import Foundation

/// What the savings calculation needs to know about a calendar year, apart from its inflation.
struct SavingsYearValues {
  let year: Int
  /// Percent of the net income left for a higher living standard, on top of inflation.
  var lifeLevelUp: Double
  /// Income tax rate in percent for income below every threshold of `higherTaxBrackets`.
  var baseTaxRate: Double
  var higherTaxBrackets: [TaxBracket]
}

/// A raised income tax rate for the part of income above a threshold.
struct TaxBracket: Hashable, Identifiable, Sendable {
  /// Tells the rows of a screen apart and nothing else: it is not stored, so a bracket read
  /// from the store again has another one.
  let id = UUID()
  /// Yearly income before tax the rate applies above.
  var threshold: Double
  /// Percent (15 means 15%).
  var rate: Double
}
