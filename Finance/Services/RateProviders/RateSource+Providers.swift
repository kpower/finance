import Foundation

/// Fetching side of `RateSource`: which sources are providers and how to load rates from them.
extension RateSource {
  /// @AppStorage key of the provider chosen in Settings; every rates editor fetches from it.
  static let selectionKey = "ratesProviderID"

  /// Fetching implementation; nil for hand-typed rates and retired providers.
  func makeProvider() -> (any RateProvider)? {
    switch self {
    case .manual: nil
    case .cbrXML: CBRXMLProvider()
    case .cbrJSON: CBRJSONProvider()
    }
  }

  var isAvailable: Bool { makeProvider() != nil }

  static var available: [RateSource] { allCases.filter(\.isAvailable) }

  /// `self` if it can fetch, otherwise the first available provider (e.g. a retired one was selected).
  var availableOrFirst: RateSource { isAvailable ? self : Self.available[0] }

  func fetch(on date: Date) async throws -> Rates {
    guard let provider = makeProvider() else { throw RateFetchError.providerUnavailable }
    return try await provider.fetch(on: date)
  }
}
