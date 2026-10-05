import SwiftData

enum FinanceSchema {
  static let models: [any PersistentModel.Type] = [Deposit.self, RateRecord.self, Snapshot.self]
}
