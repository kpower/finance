import Foundation
import SwiftData

// MARK: - Reading

extension SavingsYearValues {
  init(_ year: SavingsYear) {
    self.init(
      year: year.year, lifeLevelUp: year.lifeLevelUp, baseTaxRate: year.baseTaxRate,
      higherTaxBrackets: year.higherTaxBrackets.map { TaxBracket(threshold: $0.threshold, rate: $0.rate) }
    )
  }
}

extension Stored<SavingsYearValues> {
  init(_ year: SavingsYear) {
    self.init(id: year.persistentModelID, values: SavingsYearValues(year))
  }
}

// MARK: - Writing

extension SavingsYear {
  convenience init(_ values: SavingsYearValues) {
    self.init(
      year: values.year, lifeLevelUp: values.lifeLevelUp, baseTaxRate: values.baseTaxRate,
      higherTaxBrackets: values.higherTaxBrackets.records
    )
  }

  func update(from values: SavingsYearValues) {
    year = values.year
    lifeLevelUp = values.lifeLevelUp
    baseTaxRate = values.baseTaxRate
    higherTaxBrackets = values.higherTaxBrackets.records
  }
}

extension [TaxBracket] {
  fileprivate var records: [TaxBracketRecord] {
    map { TaxBracketRecord(threshold: $0.threshold, rate: $0.rate) }
  }
}
