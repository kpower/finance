import Foundation

enum SettingsTab: String {
  case rates
  case inflation

  /// @AppStorage key of the tab Settings shows; set before opening Settings to land on a given tab.
  static let selectionKey = "settingsTab"
}
