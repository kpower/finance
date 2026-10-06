import Foundation
import SwiftUI

/// USD/EUR rates of a history entry: typed by hand or fetched for the entry's date.
struct SnapshotRatesEditor: View {
  /// Day the entry belongs to; fetching asks the source for this day.
  let date: Date
  let rates: Rates
  /// Rates were typed by hand or obtained for another day: highlight the fetch button.
  let needsAttention: Bool
  /// New rates and the day they were obtained for (nil when typed by hand).
  let onChange: (Rates, Date?) -> Void

  @AppStorage(RateProviders.selectionKey) private var selectedProvider = RateProviders.cbrXML
  @State private var isLoading = false
  @State private var errorMessage: LocalizedStringResource?

  var body: some View {
    HStack(spacing: 12) {
      rateField(.historySnapshotRatesUsdLabel, value: Binding(get: { rates.usd }, set: { manual(usd: $0, eur: rates.eur) }))
      rateField(.historySnapshotRatesEurLabel, value: Binding(get: { rates.eur }, set: { manual(usd: rates.usd, eur: $0) }))
      fetchButton
      if let errorMessage {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
          .help(Text(errorMessage))
      } else if !rates.source.isEmpty {
        Text(RateSource.displayName(rates.source)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
    }
  }

  private func rateField(_ title: LocalizedStringResource, value: Binding<Double>) -> some View {
    HStack(spacing: 6) {
      Text(title)
      TextField(String(localized: title), value: value, format: Fmt.moneyInput)
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 90)
    }
  }

  @ViewBuilder private var fetchButton: some View {
    let provider = selectedProvider.availableOrFirst
    if isLoading {
      ProgressView().controlSize(.small)
    } else {
      Button(action: fetch) {
        Label { Text(.historySnapshotRatesFetchButton) } icon: { Image(systemName: "arrow.down.circle") }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
      .foregroundStyle(needsAttention ? .orange : .secondary)
      .help(
        needsAttention
          ? Text(.historySnapshotRatesFetchAttentionHelp(Fmt.date(date), provider.title))
          : Text(.historySnapshotRatesFetchHelp(Fmt.date(date), provider.title))
      )
    }
  }

  private func manual(usd: Double, eur: Double) {
    errorMessage = nil
    onChange(Rates(usd: usd, eur: eur, date: date, source: RateSource.manual), nil)
  }

  private func fetch() {
    let provider = selectedProvider.availableOrFirst
    let day = date
    errorMessage = nil
    isLoading = true
    Task {
      defer { isLoading = false }
      do {
        onChange(try await provider.fetch(on: day), day)
      } catch {
        errorMessage = RateFetchFailureText.text(for: error)
      }
    }
  }
}
