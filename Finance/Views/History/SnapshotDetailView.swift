import SwiftData
import SwiftUI

/// A history entry: deposits as they were on the entry's date (or only totals for archive entries).
/// Date, rates and archive totals are editable; per-deposit details are read-only.
struct SnapshotDetailView: View {
  @Bindable var snapshot: Snapshot
  @Environment(\.modelContext) private var context
  @State private var dateConflict: Date?

  private var rates: Rates { snapshot.rates }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      switch snapshot.kind {
      case .detailed: itemsTable
      case .summaryOnly: summaryNote
      }
      Divider()
      footer
    }
    .navigationTitle(snapshot.kind == .summaryOnly
      ? "Архивная запись на \(Fmt.date(snapshot.date))"
      : "Вклады на \(Fmt.date(snapshot.date))")
    .alert(
      "Дата занята",
      isPresented: Binding(get: { dateConflict != nil }, set: { if !$0 { dateConflict = nil } })
    ) {
      Button("OK") {}
    } message: {
      Text("На \(Fmt.date(dateConflict)) уже есть запись в истории. Удалите её или выберите другую дату.")
    }
  }

  // MARK: Header

  private var header: some View {
    HStack(spacing: 20) {
      DatePicker("Дата", selection: dateBinding, displayedComponents: .date)
        .datePickerStyle(.field)
        .environment(\.locale, Fmt.ruLocale)
        .fixedSize()
      SnapshotRatesEditor(
        date: snapshot.date,
        rates: rates,
        needsAttention: snapshot.ratesNeedAttention,
        onChange: snapshot.setRates
      )
      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  /// Moves the entry to another day unless that day already has an entry.
  private var dateBinding: Binding<Date> {
    Binding(
      get: { snapshot.date },
      set: { newDate in
        if SnapshotService.isDayTaken(newDate, excluding: snapshot, in: context) {
          dateConflict = newDate
        } else {
          snapshot.move(to: newDate)
        }
      }
    )
  }

  // MARK: Content

  private var itemsTable: some View {
    Table(snapshot.items) {
      TableColumn("Название") { Text($0.name) }
        .width(min: 120, ideal: 180)
      TableColumn("Банк") { Text($0.bank) }
        .width(min: 90, ideal: 130)
      TableColumn("₽") { money($0.amountRUB) }
        .width(min: 100, ideal: 115)
        .alignment(.trailing)
      TableColumn("$") { money($0.amountUSD) }
        .width(min: 90, ideal: 105)
        .alignment(.trailing)
      TableColumn("€") { money($0.amountEUR) }
        .width(min: 90, ideal: 105)
        .alignment(.trailing)
      TableColumn("Итого ₽") {
        Text($0.isEmpty ? "" : Fmt.money($0.totalRUB(at: rates)))
          .monospacedDigit().fontWeight(.semibold)
      }
      .width(min: 110, ideal: 125)
      .alignment(.trailing)
      TableColumn("%") { item in
        Text(item.interestRate.map { $0.formatted(.number.precision(.fractionLength(0...2)).locale(Fmt.ruLocale)) } ?? "")
          .monospacedDigit()
      }
      .width(min: 50, ideal: 60)
      .alignment(.trailing)
      TableColumn("Срок, мес.") { Text($0.termMonths.map(String.init) ?? "").monospacedDigit() }
        .width(min: 70, ideal: 80)
        .alignment(.trailing)
      TableColumn("Открыт") { Text(Fmt.date($0.openDate)).monospacedDigit() }
        .width(min: 80, ideal: 90)
      TableColumn("Закрытие") { Text(Fmt.date($0.closeDate)).monospacedDigit() }
        .width(min: 80, ideal: 90)
    }
  }

  private var summaryNote: some View {
    VStack(spacing: 16) {
      ContentUnavailableView(
        "Только суммы",
        systemImage: "archivebox",
        description: Text("Архивная запись без детализации по вкладам.")
      )
      .fixedSize(horizontal: false, vertical: true)
      HStack(spacing: 20) {
        sumField("₽", value: $snapshot.summaryRUB)
        sumField("$", value: $snapshot.summaryUSD)
        sumField("€", value: $snapshot.summaryEUR)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func sumField(_ title: String, value: Binding<Double>) -> some View {
    LabeledContent(title) {
      TextField(title, value: value, format: Fmt.moneyInput)
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 140)
    }
    .fixedSize()
  }

  private func money(_ value: Double?) -> some View {
    Text(Fmt.money(value)).monospacedDigit()
  }

  // MARK: Footer

  private var footer: some View {
    HStack(alignment: .firstTextBaseline, spacing: 24) {
      Spacer()
      sum("Σ ₽", snapshot.sumRUB)
      sum("Σ $", snapshot.sumUSD)
      sum("Σ €", snapshot.sumEUR)
      VStack(alignment: .trailing, spacing: 2) {
        Text("Итого в ₽").font(.caption).foregroundStyle(.secondary)
        Text(Fmt.money(snapshot.totalRUB)).font(.title3.weight(.semibold)).monospacedDigit()
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.bar)
  }

  private func sum(_ title: String, _ value: Double) -> some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(Fmt.money(value)).monospacedDigit()
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  let snapshot = (try? container.mainContext.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)])))?.last
  return NavigationStack {
    if let snapshot { SnapshotDetailView(snapshot: snapshot) }
  }
  .modelContainer(container)
  .frame(width: 1100, height: 400)
}
