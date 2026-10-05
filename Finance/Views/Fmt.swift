import Foundation

/// Shared number/date formats so all sections look the same.
enum Fmt {
  static let ruLocale = Locale(identifier: "ru_RU")

  /// 1 234 567,89
  static func money(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(2)).locale(ruLocale))
  }

  /// Empty string for nil, so table cells stay blank.
  static func money(_ value: Double?) -> String {
    value.map(money) ?? ""
  }

  /// +1 234,56 / −1 234,56
  static func signedMoney(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(2)).sign(strategy: .always()).locale(ruLocale))
  }

  /// 92,5432
  static func rate(_ value: Double) -> String {
    value.formatted(.number.precision(.fractionLength(4)).locale(ruLocale))
  }

  /// 05.10.2026
  static func date(_ value: Date) -> String {
    value.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().locale(ruLocale))
  }

  static func date(_ value: Date?) -> String {
    value.map(date) ?? ""
  }

  /// Input format for editable money fields (no forced fraction digits).
  static let moneyInput = FloatingPointFormatStyle<Double>.number.locale(ruLocale)
}
