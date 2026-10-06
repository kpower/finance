import Foundation

/// Known rate sources. The raw value is stored in data as the rates' `RateSource`,
/// so a case is never removed: a retired provider keeps its case (for display of
/// old records) and `makeProvider()` returns nil for it.
enum RateProviders: String, CaseIterable, Identifiable {
  case cbrXML = "cbr-xml"
  case cbrJSON = "cbr-json"

  /// @AppStorage key of the provider chosen in the Rates section; history uses the same one.
  static let selectionKey = "ratesProviderID"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .cbrXML: String(localized: .rateProviderCbrXmlTitle)
    case .cbrJSON: String(localized: .rateProviderCbrJsonTitle)
    }
  }

  /// Fetching implementation; nil for retired providers.
  func makeProvider() -> (any RateProvider)? {
    switch self {
    case .cbrXML: CBRXMLProvider()
    case .cbrJSON: CBRJSONProvider()
    }
  }

  var isAvailable: Bool { makeProvider() != nil }

  /// Providers that can fetch rates, in display order.
  static var available: [RateProviders] { allCases.filter(\.isAvailable) }

  /// `self` if it can still fetch, otherwise the first available provider (e.g. a retired one was selected).
  var availableOrFirst: RateProviders { isAvailable ? self : Self.available[0] }

  /// Rates for the given date (latest when nil), tagged with this provider as their source.
  func fetch(on date: Date?) async throws -> Rates {
    guard let provider = makeProvider() else { throw RateFetchError.providerUnavailable }
    var rates = try await provider.fetch(on: date)
    rates.source = rawValue
    return rates
  }
}
