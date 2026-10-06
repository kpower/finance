import Foundation
import SwiftUI

/// Totals per currency and grand total in rubles, shown under the deposits table.
struct DepositsSummaryBar: View {
  let deposits: [Deposit]
  let rates: Rates

  var body: some View {
    let rub = deposits.reduce(0) { $0 + ($1.amountRUB ?? 0) }
    let usd = deposits.reduce(0) { $0 + ($1.amountUSD ?? 0) }
    let eur = deposits.reduce(0) { $0 + ($1.amountEUR ?? 0) }
    let missing = (usd != 0 && rates.usd <= 0) || (eur != 0 && rates.eur <= 0)

    VStack(alignment: .trailing, spacing: 4) {
      HStack(spacing: 20) {
        total("₽", Fmt.money(rub))
        total("$", Fmt.money(usd))
        total("€", Fmt.money(eur))
        Divider().frame(height: 16)
        HStack(spacing: 6) {
          Text(.depositsSummaryTotalRubLabel).foregroundStyle(.secondary)
          if missing {
            Text(.depositsSummaryNoRateLabel).foregroundStyle(.secondary)
          } else {
            Text(Fmt.money(rub + usd * rates.usd + eur * rates.eur)).bold()
          }
        }
      }
      Text(ratesLine)
        .font(.caption)
        .foregroundStyle(.secondary)
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

  private var ratesLine: LocalizedStringResource {
    guard rates.usd > 0 || rates.eur > 0 else { return .depositsSummaryRatesMissingLabel }
    if let date = rates.date {
      return .depositsSummaryRatesOnDateLabel(Fmt.rate(rates.usd), Fmt.rate(rates.eur), Fmt.date(date))
    }
    return .depositsSummaryRatesLabel(Fmt.rate(rates.usd), Fmt.rate(rates.eur))
  }
}
