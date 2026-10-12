import Foundation
import SwiftUI

/// Totals per currency and grand total in rubles, shown under the deposits table,
/// with the rates used for the total editable in place.
struct DepositsSummaryBar: View {
  let deposits: [Deposit]
  /// Nil when not entered yet.
  let rates: Rates?
  let onRatesChange: (Rates) -> Void

  var body: some View {
    let rub = deposits.reduce(0) { $0 + ($1.amountRUB ?? 0) }
    let usd = deposits.reduce(0) { $0 + ($1.amountUSD ?? 0) }
    let eur = deposits.reduce(0) { $0 + ($1.amountEUR ?? 0) }
    // Without rates the total is known only when there is nothing to convert.
    let totalRUB = rates.map { rub + usd * $0.usd + eur * $0.eur } ?? (usd == 0 && eur == 0 ? rub : nil)

    VStack(alignment: .trailing, spacing: 6) {
      HStack(spacing: 20) {
        total("₽", Fmt.money(rub))
        total("$", Fmt.money(usd))
        total("€", Fmt.money(eur))
        Divider().frame(height: 16)
        HStack(spacing: 6) {
          Text(.depositsSummaryTotalRubLabel).foregroundStyle(.secondary)
          if let totalRUB {
            Text(Fmt.money(totalRUB)).bold()
          } else {
            Text(.depositsSummaryNoRateLabel).foregroundStyle(.secondary)
          }
        }
      }
      RatesEditor(date: .now, rates: rates, onChange: onRatesChange)
    }
    .monospacedDigit()
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(.bar)
  }

  private func total(_ symbol: String, _ value: String) -> some View {
    HStack(spacing: 6) {
      Text(symbol).foregroundStyle(.secondary)
      Text(value)
    }
  }
}
