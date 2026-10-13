import Foundation

/// Shared number/date formats so all sections look the same. Follow the user's region settings.
enum Fmt {
  /// 1 234 567,89
  static func money(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(2)))
  }

  /// Empty string for nil, so table cells stay blank.
  static func money(_ value: Double?) -> String {
    value.map(money) ?? ""
  }

  /// +1 234,56 / −1 234,56
  static func signedMoney(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always()))
  }

  /// 2,4 млн
  static func compactMoney(_ value: Double) -> String {
    value.formatted(.number.notation(.compactName))
  }

  /// 92,5432
  static func rate(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(4)))
  }

  /// 18,5 — interest rate in percent, no trailing zeros.
  static func percent(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(0...2)))
  }

  /// 05.10.2026
  static func date(_ value: Date) -> String {
    value.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
  }

  static func date(_ value: Date?) -> String {
    value.map(date) ?? ""
  }

  /// Input format for editable money fields (no forced fraction digits).
  static let moneyInput = FloatingPointFormatStyle<Double>.number
}
