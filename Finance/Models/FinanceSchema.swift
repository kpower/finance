import SwiftData

enum FinanceSchema {
  static let models: [any PersistentModel.Type] = [
    Snapshot.self, SavingsEntry.self, SavingsYear.self, AnnualInflation.self
  ]
}
