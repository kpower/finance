import Foundation

/// Fetching side of `RateSource`: which sources are providers and how to load rates from them.
/// Fetching is always user-initiated.
extension RateSource {
  /// False for hand-typed rates and retired providers.
  var isAvailable: Bool {
    switch self {
    case .manual: false
    case .cbrXML, .cbrJSON: true
    }
  }

  static var available: [RateSource] { allCases.filter(\.isAvailable) }

  func fetch(on date: Date) async throws -> Rates {
    switch self {
    case .manual: throw RateFetchError.providerUnavailable
    case .cbrXML: try await CBRXMLProvider.fetch(on: date)
    case .cbrJSON: try await CBRJSONProvider.fetch(on: date)
    }
  }
}
