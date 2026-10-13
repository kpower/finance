import Foundation
import SwiftUI

/// USD/EUR rates of a history entry, typed by hand or fetched for its date.
struct RatesEditor: View {
  /// Day the rates are for; fetching asks the source for this day.
  let date: Date
  let rates: Rates?
  let onChange: (Rates) -> Void

  @SelectedRateProvider private var provider: RateSource
  /// Values in the fields. They become rates only once both are filled in.
  @State private var usd: Double?
  @State private var eur: Double?
  @State private var isLoading = false
  @State private var errorMessage: LocalizedStringResource?

  /// Rates are missing, typed by hand or obtained for another day: highlight the fetch button.
  private var needsAttention: Bool { rates?.needAttention(on: date) ?? true }

  var body: some View {
    HStack(spacing: 12) {
      rateField(.ratesEditorUsdLabel, value: $usd)
      rateField(.ratesEditorEurLabel, value: $eur)
      fetchButton
      if let errorMessage {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
          .help(Text(errorMessage))
      } else if let rates {
        Text(rates.source.title).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
    }
    // Never squeezed by its neighbors: a compressed label wraps one letter per line.
    .fixedSize()
    .onChange(of: rates, initial: true) {
      usd = rates?.usd
      eur = rates?.eur
    }
    .onChange(of: usd) { applyTyped() }
    .onChange(of: eur) { applyTyped() }
  }

  private func rateField(_ title: LocalizedStringResource, value: Binding<Double?>) -> some View {
    HStack(spacing: 6) {
      Text(title)
      TextField(String(localized: title), value: value, format: Fmt.moneyInput, prompt: Text(verbatim: "0"))
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 90)
    }
  }

  @ViewBuilder private var fetchButton: some View {
    if isLoading {
      ProgressView().controlSize(.small)
    } else {
      Button(action: fetch) {
        Label { Text(.ratesEditorFetchButton) } icon: { Image(systemName: "arrow.down.circle") }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
      .foregroundStyle(needsAttention ? .orange : .secondary)
      .help(
        needsAttention
          ? Text(.ratesEditorFetchAttentionHelp(Fmt.date(date), provider.title))
          : Text(.ratesEditorFetchHelp(Fmt.date(date), provider.title))
      )
    }
  }

  /// Reports the typed values as manual rates once both are filled in and differ from `rates`
  /// (so showing fetched rates in the fields does not turn them into manual ones).
  private func applyTyped() {
    guard let usd, let eur, usd > 0, eur > 0 else { return }
    guard usd != rates?.usd || eur != rates?.eur else { return }
    errorMessage = nil
    onChange(Rates(usd: usd, eur: eur, date: date, source: .manual))
  }

  private func fetch() {
    let day = date
    errorMessage = nil
    isLoading = true
    Task {
      defer { isLoading = false }
      do {
        onChange(try await provider.fetch(on: day))
      } catch {
        errorMessage = RateFetchFailureText.text(for: error)
      }
    }
  }
}
