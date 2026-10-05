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

  @AppStorage(RateProviders.selectionKey) private var providerID = RateProviders.all[0].id
  @State private var isLoading = false
  @State private var errorMessage: String?

  var body: some View {
    HStack(spacing: 12) {
      rateField("Курс $", value: Binding(get: { rates.usd }, set: { manual(usd: $0, eur: rates.eur) }))
      rateField("Курс €", value: Binding(get: { rates.eur }, set: { manual(usd: rates.usd, eur: $0) }))
      fetchButton
      if let errorMessage {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(.red)
          .help(errorMessage)
      } else if !rates.source.isEmpty {
        Text(rates.source).font(.caption).foregroundStyle(.secondary).lineLimit(1)
      }
    }
  }

  private func rateField(_ title: String, value: Binding<Double>) -> some View {
    HStack(spacing: 6) {
      Text(title)
      TextField(title, value: value, format: Fmt.moneyInput)
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 90)
    }
  }

  @ViewBuilder private var fetchButton: some View {
    let provider = RateProviders.provider(id: providerID)
    if isLoading {
      ProgressView().controlSize(.small)
    } else {
      Button("Загрузить курс на дату", systemImage: "arrow.down.circle", action: fetch)
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(needsAttention ? .orange : .secondary)
        .help(
          needsAttention
            ? "Курс введён вручную или получен на другую дату. Загрузить курс на \(Fmt.date(date)) (\(provider.title))"
            : "Загрузить курс на \(Fmt.date(date)) (\(provider.title))"
        )
    }
  }

  private func manual(usd: Double, eur: Double) {
    errorMessage = nil
    onChange(Rates(usd: usd, eur: eur, date: date, source: Rates.manualSource), nil)
  }

  private func fetch() {
    let provider = RateProviders.provider(id: providerID)
    let day = date
    errorMessage = nil
    isLoading = true
    Task {
      defer { isLoading = false }
      do {
        var fetched = try await provider.fetch(on: day)
        fetched.source = provider.title
        onChange(fetched, day)
      } catch {
        errorMessage = error.localizedDescription
      }
    }
  }
}
