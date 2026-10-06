import Foundation

/// Stable identifiers stored in `RateRecord.source` and `Snapshot.ratesSource`.
/// Stored values are never shown as is: `displayName` localizes them.
enum RateSource {
  static let manual = "manual"

  /// Display names stored before sources became identifiers.
  private static let legacy = [
    "Вручную": manual,
    "ЦБ РФ (XML)": RateProviders.cbrXML.rawValue,
    "cbr-xml-daily.ru (JSON)": RateProviders.cbrJSON.rawValue,
  ]

  private static func normalized(_ stored: String) -> String {
    legacy[stored] ?? stored
  }

  static func isManual(_ stored: String) -> Bool {
    normalized(stored) == manual
  }

  /// Localized name; unknown values are shown verbatim.
  static func displayName(_ stored: String) -> String {
    let id = normalized(stored)
    if id == manual { return String(localized: .rateSourceManualName) }
    return RateProviders(rawValue: id)?.title ?? stored
  }
}
