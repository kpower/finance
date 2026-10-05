import Foundation

/// Value copy of a deposit as it was at snapshot time.
struct DepositRecord: Codable, Hashable, Identifiable, Sendable, DepositAmounts {
  var id = UUID()
  var name: String
  var bank: String
  var amountRUB: Double?
  var amountUSD: Double?
  var amountEUR: Double?
  var interestRate: Double?
  var termMonths: Int?
  var openDate: Date?
  var closeDate: Date?
}
