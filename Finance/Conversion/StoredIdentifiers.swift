import Foundation

// What the store, backups and settings hold in place of an enum case.
// An identifier is never changed or given to another case: stored data refers to it.

extension RateSource {
  /// A retired provider keeps its case and identifier, for the entries that still name it.
  var storedID: String {
    switch self {
    case .manual: "manual"
    case .cbrXML: "cbr-xml"
    case .cbrJSON: "cbr-json"
    }
  }

  init?(storedID: String) {
    guard let source = Self.allCases.first(where: { $0.storedID == storedID }) else { return nil }
    self = source
  }
}

extension SnapshotKind {
  var storedID: String {
    switch self {
    case .detailed: "detailed"
    case .summaryOnly: "summaryOnly"
    }
  }

  init?(storedID: String) {
    guard let kind = Self.allCases.first(where: { $0.storedID == storedID }) else { return nil }
    self = kind
  }
}
