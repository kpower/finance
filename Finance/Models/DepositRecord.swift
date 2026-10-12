import Foundation

/// Value copy of a deposit as it was at snapshot time.
struct DepositRecord: Codable, Hashable, Identifiable, Sendable, DepositAmounts {
  var id = UUID()
  let name: String
  let bank: String
  let amountRUB: Double?
  let amountUSD: Double?
  let amountEUR: Double?
  let interestRate: Double?
  let termMonths: Int?
  let openDate: Date?
  let closeDate: Date?
}
