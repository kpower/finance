import SwiftUI

/// Read-only cells shared by the sections' tables.
enum Cell {
  static func money(_ value: Double?, bold: Bool = false) -> some View {
    Text(Fmt.money(value)).monospacedDigit().fontWeight(bold ? .semibold : .regular)
  }

  /// Green for growth, red for decline; blank when there is nothing to compare with.
  static func delta(_ value: Double?) -> some View {
    Text(value.map(Fmt.signedMoney) ?? "")
      .monospacedDigit()
      .foregroundStyle(value.map { $0 > 0 ? Color.green : $0 < 0 ? .red : .secondary } ?? .secondary)
  }
}
