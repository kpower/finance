import SwiftData
import SwiftUI

struct RatesView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \RateRecord.createdAt, order: .reverse) private var records: [RateRecord]
  @AppStorage(RateProviders.selectionKey) private var selectedProvider = RateProviders.cbrXML

  @State private var manualUSD: Double?
  @State private var manualEUR: Double?
  @State private var manualDate = Date.now

  @State private var useDate = false
  @State private var fetchDate = Date.now
  @State private var isLoading = false
  @State private var fetchTask: Task<Void, Never>?
  @State private var preview: Rates?
  @State private var errorMessage: LocalizedStringResource?
  @State private var selection = Set<RateRecord.ID>()

  /// Selected provider; falls back to an available one if the stored choice was retired.
  private var provider: Binding<RateProviders> {
    Binding(get: { selectedProvider.availableOrFirst }, set: { selectedProvider = $0 })
  }

  private var manualValid: Bool {
    (manualUSD ?? 0) > 0 && (manualEUR ?? 0) > 0
  }

  var body: some View {
    Form {
      currentSection
      manualSection
      fetchSection
      historySection
      sourcesSection
    }
    .formStyle(.grouped)
    .navigationTitle(Text(.ratesNavigationTitle))
  }

  // MARK: Current

  private var currentSection: some View {
    Section {
      if let latest = records.first {
        HStack(alignment: .top, spacing: 48) {
          bigRate("USD", latest.usd)
          bigRate("EUR", latest.eur)
          Spacer()
          VStack(alignment: .trailing, spacing: 4) {
            Text(.ratesCurrentRateDateLabel(Fmt.date(latest.rateDate)))
            Text(.ratesCurrentSourceLabel(RateSource.displayName(latest.source)))
            Text(.ratesCurrentAppliedLabel(Fmt.dateTime(latest.createdAt)))
          }
          .font(.callout)
          .foregroundStyle(.secondary)
        }
      } else {
        Text(.ratesCurrentEmptyLabel)
          .foregroundStyle(.secondary)
      }
    } header: {
      Text(.ratesCurrentHeader)
    }
  }

  private func bigRate(_ code: String, _ value: Double) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(verbatim: "\(code) → RUB").font(.callout).foregroundStyle(.secondary)
      Text(Fmt.rate(value)).font(.system(size: 34, weight: .semibold)).monospacedDigit()
    }
  }

  // MARK: Manual

  private var manualSection: some View {
    Section {
      TextField(value: $manualUSD, format: Fmt.moneyInput, prompt: Text(verbatim: Fmt.rate(0))) {
        Text(.ratesManualUsdField)
      }
      TextField(value: $manualEUR, format: Fmt.moneyInput, prompt: Text(verbatim: Fmt.rate(0))) {
        Text(.ratesManualEurField)
      }
      DatePicker(selection: $manualDate, displayedComponents: .date) { Text(.ratesManualDateField) }
      HStack {
        Spacer()
        Button {
          guard let usd = manualUSD, let eur = manualEUR else { return }
          apply(Rates(usd: usd, eur: eur, date: manualDate, source: RateSource.manual))
          manualUSD = nil
          manualEUR = nil
        } label: {
          Text(.ratesManualApplyButton)
        }
        .disabled(!manualValid)
      }
    } header: {
      Text(.ratesManualHeader)
    }
  }

  // MARK: Fetch

  private var fetchSection: some View {
    Section {
      Picker(selection: provider) {
        ForEach(RateProviders.available) { Text($0.title).tag($0) }
      } label: {
        Text(.ratesFetchSourcePicker)
      }
      Toggle(isOn: $useDate) { Text(.ratesFetchOnDateToggle) }
      if useDate {
        DatePicker(selection: $fetchDate, in: ...Date.now, displayedComponents: .date) { Text(.ratesFetchDateField) }
      }
      HStack {
        if isLoading {
          ProgressView().controlSize(.small)
          Text(.ratesFetchLoadingLabel).foregroundStyle(.secondary)
        }
        Spacer()
        Button(action: startFetch) { Text(.ratesFetchLoadButton) }.disabled(isLoading)
      }
      if let errorMessage {
        Text(errorMessage).foregroundStyle(.red)
      }
      if let preview {
        previewBox(preview)
      }
    } header: {
      Text(.ratesFetchHeader)
    }
  }

  private func previewBox(_ rates: Rates) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(.ratesPreviewTitle(RateSource.displayName(rates.source))).font(.headline)
      HStack(spacing: 40) {
        bigRate("USD", rates.usd)
        bigRate("EUR", rates.eur)
        if let date = rates.date {
          Text(.ratesPreviewRateDateLabel(Fmt.date(date))).foregroundStyle(.secondary)
        }
      }
      HStack {
        Spacer()
        Button { preview = nil } label: { Text(.ratesPreviewCancelButton) }
        Button {
          apply(rates)
          preview = nil
        } label: {
          Text(.ratesPreviewApplyButton)
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(12)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
  }

  private func startFetch() {
    let provider = provider.wrappedValue
    let date = useDate ? fetchDate : nil
    errorMessage = nil
    preview = nil
    isLoading = true
    fetchTask?.cancel()
    fetchTask = Task {
      defer { isLoading = false }
      do {
        let rates = try await provider.fetch(on: date)
        if !Task.isCancelled { preview = rates }
      } catch {
        if !Task.isCancelled { errorMessage = RateFetchFailureText.text(for: error) }
      }
    }
  }

  private func apply(_ rates: Rates) {
    context.insert(RateRecord(
      rateDate: rates.date ?? .now, usd: rates.usd, eur: rates.eur, source: rates.source))
  }

  // MARK: History

  private var historySection: some View {
    Section {
      Table(records, selection: $selection) {
        TableColumn(Text(.ratesHistoryTableAppliedColumn)) { Text(Fmt.dateTime($0.createdAt)) }
        TableColumn(Text(.ratesHistoryTableRateDateColumn)) { Text(Fmt.date($0.rateDate)) }
        TableColumn(Text(verbatim: "USD")) { Text(Fmt.rate($0.usd)).monospacedDigit() }
        TableColumn(Text(verbatim: "EUR")) { Text(Fmt.rate($0.eur)).monospacedDigit() }
        TableColumn(Text(.ratesHistoryTableSourceColumn)) { record in
          HStack {
            Text(RateSource.displayName(record.source))
            if record.id == records.first?.id {
              Text(.ratesHistoryTableCurrentBadge).font(.caption).foregroundStyle(.green)
            }
          }
        }
      }
      .contextMenu(forSelectionType: RateRecord.ID.self) { ids in
        let picked = records.filter { ids.contains($0.id) }
        if picked.count == 1, let record = picked.first, record.id != records.first?.id {
          Button {
            context.insert(RateRecord(
              rateDate: record.rateDate, usd: record.usd, eur: record.eur, source: record.source))
          } label: {
            Text(.ratesHistoryContextMenuMakeCurrentButton)
          }
        }
        if !picked.isEmpty {
          Button(role: .destructive) {
            picked.forEach(context.delete)
            selection.subtract(ids)
          } label: {
            Text(.ratesHistoryContextMenuDeleteButton)
          }
        }
      }
      .frame(minHeight: 220)
    } header: {
      Text(.ratesHistoryHeader)
    }
  }

  // MARK: Sources help

  private var sourcesSection: some View {
    Section {
      DisclosureGroup {
        VStack(alignment: .leading, spacing: 8) {
          source(.ratesSourcesCbrXmlName, .ratesSourcesCbrXmlDescription)
          source(.ratesSourcesCbrJsonName, .ratesSourcesCbrJsonDescription)
          source(.ratesSourcesMoexName, .ratesSourcesMoexDescription)
          source(.ratesSourcesBanksName, .ratesSourcesBanksDescription)
        }
        .font(.callout)
        .padding(.vertical, 4)
      } label: {
        Text(.ratesSourcesDisclosure)
      }
    }
  }

  private func source(_ name: LocalizedStringResource, _ text: LocalizedStringResource) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(name).bold()
      Text(text).foregroundStyle(.secondary)
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
  container.mainContext.insert(RateRecord(
    rateDate: .now, usd: 83.4839, eur: 94.3201, source: RateProviders.cbrXML.rawValue))
  container.mainContext.insert(RateRecord(
    rateDate: .now.addingTimeInterval(-86400 * 3), usd: 82.1, eur: 92.7, source: RateSource.manual,
    createdAt: .now.addingTimeInterval(-86400 * 3)))
  return RatesView().modelContainer(container).frame(width: 760, height: 900)
}
