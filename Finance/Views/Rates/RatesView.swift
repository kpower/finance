import SwiftData
import SwiftUI

struct RatesView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \RateRecord.createdAt, order: .reverse) private var records: [RateRecord]
  @AppStorage("ratesProviderID") private var providerID = RateProviders.all[0].id

  @State private var manualUSD: Double?
  @State private var manualEUR: Double?
  @State private var manualDate = Date.now

  @State private var useDate = false
  @State private var fetchDate = Date.now
  @State private var isLoading = false
  @State private var fetchTask: Task<Void, Never>?
  @State private var preview: Rates?
  @State private var errorMessage: String?
  @State private var selection = Set<RateRecord.ID>()

  private var provider: any RateProvider {
    RateProviders.all.first { $0.id == providerID } ?? RateProviders.all[0]
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
    .navigationTitle("Курсы валют")
  }

  // MARK: Current

  private var currentSection: some View {
    Section("Действующий курс") {
      if let latest = records.first {
        HStack(alignment: .top, spacing: 48) {
          bigRate("USD", latest.usd)
          bigRate("EUR", latest.eur)
          Spacer()
          VStack(alignment: .trailing, spacing: 4) {
            Text("Курс на \(Fmt.date(latest.rateDate))")
            Text("Источник: \(latest.source)")
            Text("Применён \(applied(latest.createdAt))")
          }
          .font(.callout)
          .foregroundStyle(.secondary)
        }
      } else {
        Text("Курс не задан. Загрузите его из источника или введите вручную.")
          .foregroundStyle(.secondary)
      }
    }
  }

  private func bigRate(_ code: String, _ value: Double) -> some View {
    VStack(alignment: .leading, spacing: 2) {
      Text("\(code) → RUB").font(.callout).foregroundStyle(.secondary)
      Text(Fmt.rate(value)).font(.system(size: 34, weight: .semibold)).monospacedDigit()
    }
  }

  // MARK: Manual

  private var manualSection: some View {
    Section("Ввести вручную") {
      TextField("USD, ₽", value: $manualUSD, format: Fmt.moneyInput, prompt: Text("0,0000"))
      TextField("EUR, ₽", value: $manualEUR, format: Fmt.moneyInput, prompt: Text("0,0000"))
      DatePicker("Дата курса", selection: $manualDate, displayedComponents: .date)
      HStack {
        Spacer()
        Button("Применить") {
          guard let usd = manualUSD, let eur = manualEUR else { return }
          apply(Rates(usd: usd, eur: eur, date: manualDate), source: "Вручную")
          manualUSD = nil
          manualEUR = nil
        }
        .disabled(!manualValid)
      }
    }
  }

  // MARK: Fetch

  private var fetchSection: some View {
    Section("Загрузить из источника") {
      Picker("Источник", selection: $providerID) {
        ForEach(RateProviders.all, id: \.id) { Text($0.title).tag($0.id) }
      }
      Toggle("На дату", isOn: $useDate)
      if useDate {
        DatePicker("Дата", selection: $fetchDate, in: ...Date.now, displayedComponents: .date)
      }
      HStack {
        if isLoading {
          ProgressView().controlSize(.small)
          Text("Загрузка…").foregroundStyle(.secondary)
        }
        Spacer()
        Button("Загрузить курс", action: startFetch).disabled(isLoading)
      }
      if let errorMessage {
        Text(errorMessage).foregroundStyle(.red)
      }
      if let preview {
        previewBox(preview)
      }
    }
  }

  private func previewBox(_ rates: Rates) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Предпросмотр: \(provider.title)").font(.headline)
      HStack(spacing: 40) {
        bigRate("USD", rates.usd)
        bigRate("EUR", rates.eur)
        if let date = rates.date {
          Text("Курс на \(Fmt.date(date))").foregroundStyle(.secondary)
        }
      }
      HStack {
        Spacer()
        Button("Отмена") { preview = nil }
        Button("Применить") {
          apply(rates, source: provider.title)
          preview = nil
        }
        .keyboardShortcut(.defaultAction)
      }
    }
    .padding(12)
    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
  }

  private func startFetch() {
    let provider = provider
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
        if !Task.isCancelled { errorMessage = error.localizedDescription }
      }
    }
  }

  private func apply(_ rates: Rates, source: String) {
    context.insert(RateRecord(
      rateDate: rates.date ?? .now, usd: rates.usd, eur: rates.eur, source: source))
  }

  // MARK: History

  private var historySection: some View {
    Section("История курсов") {
      Table(records, selection: $selection) {
        TableColumn("Применён") { Text(applied($0.createdAt)) }
        TableColumn("Дата курса") { Text(Fmt.date($0.rateDate)) }
        TableColumn("USD") { Text(Fmt.rate($0.usd)).monospacedDigit() }
        TableColumn("EUR") { Text(Fmt.rate($0.eur)).monospacedDigit() }
        TableColumn("Источник") { record in
          HStack {
            Text(record.source)
            if record.id == records.first?.id {
              Text("текущий").font(.caption).foregroundStyle(.green)
            }
          }
        }
      }
      .contextMenu(forSelectionType: RateRecord.ID.self) { ids in
        let picked = records.filter { ids.contains($0.id) }
        if picked.count == 1, let record = picked.first, record.id != records.first?.id {
          Button("Сделать текущим") {
            context.insert(RateRecord(
              rateDate: record.rateDate, usd: record.usd, eur: record.eur, source: record.source))
          }
        }
        if !picked.isEmpty {
          Button("Удалить", role: .destructive) {
            picked.forEach(context.delete)
            selection.subtract(ids)
          }
        }
      }
      .frame(minHeight: 220)
    }
  }

  private func applied(_ date: Date) -> String {
    date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year().hour().minute().locale(Fmt.ruLocale))
  }

  // MARK: Sources help

  private var sourcesSection: some View {
    Section {
      DisclosureGroup("Источники") {
        VStack(alignment: .leading, spacing: 8) {
          source("ЦБ РФ (XML)", "официальный курс, ключ не нужен; публикуется на следующий рабочий день.")
          source("cbr-xml-daily.ru (JSON)", "удобное зеркало курсов ЦБ с архивом; неофициальное, без гарантий доступности.")
          source("MOEX ISS", "биржевые данные; торги USD/EUR на Мосбирже прекращены в июне 2024, остались только внебиржевые/индикативные курсы. Не реализовано.")
          source("Коммерческие курсы банков", "например публичный endpoint T-Банка currency_rates: отражает курс покупки/продажи банка, но неофициальный и может измениться. Не реализовано.")
        }
        .font(.callout)
        .padding(.vertical, 4)
      }
    }
  }

  private func source(_ name: String, _ text: String) -> some View {
    Text("\(Text(name).bold()) — \(text)").foregroundStyle(.secondary)
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
  container.mainContext.insert(RateRecord(
    rateDate: .now, usd: 83.4839, eur: 94.3201, source: "ЦБ РФ (XML)"))
  container.mainContext.insert(RateRecord(
    rateDate: .now.addingTimeInterval(-86400 * 3), usd: 82.1, eur: 92.7, source: "Вручную",
    createdAt: .now.addingTimeInterval(-86400 * 3)))
  return RatesView().modelContainer(container).frame(width: 760, height: 900)
}
