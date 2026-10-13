import Foundation
import SwiftData

// MARK: - Reading

extension AnnualInflationValues {
  init(_ inflation: AnnualInflation) {
    self.init(year: inflation.year, percent: inflation.percent)
  }
}

extension Stored<AnnualInflationValues> {
  init(_ inflation: AnnualInflation) {
    self.init(id: inflation.persistentModelID, values: AnnualInflationValues(inflation))
  }
}

// MARK: - Writing

extension AnnualInflation {
  convenience init(_ values: AnnualInflationValues) {
    self.init(year: values.year, percent: values.percent)
  }

  func update(from values: AnnualInflationValues) {
    year = values.year
    percent = values.percent
  }
}
