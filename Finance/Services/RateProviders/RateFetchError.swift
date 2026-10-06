import Foundation

/// Why a rate source failed. Not user-facing: the UI picks its own text by case.
/// Transport failures are thrown as the system `URLError`.
enum RateFetchError: Error {
  case badStatus(Int)
  case notFound
  case malformed
  case missingCurrency(String)
  /// The selected provider has been retired.
  case providerUnavailable
}
