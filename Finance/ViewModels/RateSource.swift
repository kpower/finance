import Foundation

/// Where exchange rates came from: typed by hand or fetched from a provider.
enum RateSource: CaseIterable, Identifiable, Sendable {
  case manual
  case cbrXML
  case cbrJSON

  var id: Self { self }

  var title: String {
    switch self {
    case .manual: String(localized: .rateSourceManualName)
    case .cbrXML: String(localized: .rateProviderCbrXmlTitle)
    case .cbrJSON: String(localized: .rateProviderCbrJsonTitle)
    }
  }
}
