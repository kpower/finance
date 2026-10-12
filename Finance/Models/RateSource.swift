import Foundation

/// Where exchange rates came from: typed by hand or fetched from a provider.
/// The raw value is stored in data, so a case is never renamed or removed: a retired
/// provider keeps its case (for display of old records) and `makeProvider()` returns nil for it.
enum RateSource: String, Codable, CaseIterable, Identifiable, Sendable {
  case manual
  case cbrXML = "cbr-xml"
  case cbrJSON = "cbr-json"

  var id: String { rawValue }

  var title: String {
    switch self {
    case .manual: String(localized: .rateSourceManualName)
    case .cbrXML: String(localized: .rateProviderCbrXmlTitle)
    case .cbrJSON: String(localized: .rateProviderCbrJsonTitle)
    }
  }
}
