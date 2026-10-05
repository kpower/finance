import SwiftData
import SwiftUI

struct HistoryView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \Snapshot.date) private var snapshots: [Snapshot]

  @State private var path: [PersistentIdentifier] = []
  @State private var selection: Set<PersistentIdentifier> = []
  @State private var pendingDelete: Set<PersistentIdentifier> = []
  @State private var isAddingArchive = false
  @SceneStorage("historyColumns") private var customization = TableColumnCustomization<HistoryRow>()

  private var rows: [HistoryRow] { HistoryCalculator.rows(for: snapshots).reversed() }

  var body: some View {
    NavigationStack(path: $path) {
      Group {
        if snapshots.isEmpty {
          ContentUnavailableView(
            "История пуста",
            systemImage: "clock.arrow.circlepath",
            description: Text("Записи появляются после нажатия кнопки «Сохранить в историю» в разделе «Вклады». Прошлые даты можно добавить архивной записью.")
          )
        } else {
          VSplitView {
            HistoryCharts(rows: rows)
              .frame(minHeight: 180, idealHeight: 240)
            table
              .frame(minHeight: 160)
          }
        }
      }
      .navigationTitle("История")
      .toolbar {
        Button("Добавить архивную запись", systemImage: "archivebox", action: { isAddingArchive = true })
          .help("Добавить прошлую дату: только суммы по валютам, без распределения по вкладам")
      }
      .sheet(isPresented: $isAddingArchive) {
        ArchiveEntrySheet()
      }
      .navigationDestination(for: PersistentIdentifier.self) { id in
        if let snapshot = snapshots.first(where: { $0.persistentModelID == id }) {
          SnapshotDetailView(snapshot: snapshot)
        } else {
          ContentUnavailableView("Запись удалена", systemImage: "trash")
        }
      }
    }
    .confirmationDialog(
      "Удалить выбранные записи истории?",
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button("Удалить", role: .destructive) { delete(pendingDelete) }
    } message: {
      Text("Записей: \(pendingDelete.count). Это действие нельзя отменить.")
    }
  }

  private var table: some View {
    Table(of: HistoryRow.self, selection: $selection, columnCustomization: $customization) {
      Group {
        TableColumn("Дата") { (row: HistoryRow) in
          HStack(spacing: 4) {
            Text(Fmt.date(row.date)).monospacedDigit()
            if row.isSummaryOnly {
              Image(systemName: "archivebox")
                .foregroundStyle(.secondary)
                .help("Архивная запись: только суммы, без распределения по вкладам")
            }
          }
        }
          .width(min: 100, ideal: 110)
          .customizationID("date")
        TableColumn("₽") { (r: HistoryRow) in Cell.money(r.sumRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("rub")
        TableColumn("$") { (r: HistoryRow) in Cell.money(r.sumUSD) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("usd")
        TableColumn("Курс $") { (r: HistoryRow) in Cell.rate(r.usdRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("usdRate")
        TableColumn("$ в ₽") { (r: HistoryRow) in Cell.money(r.usdInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("usdInRub")
        TableColumn("€") { (r: HistoryRow) in Cell.money(r.sumEUR) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("eur")
        TableColumn("Курс €") { (r: HistoryRow) in Cell.rate(r.eurRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("eurRate")
        TableColumn("€ в ₽") { (r: HistoryRow) in Cell.money(r.eurInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("eurInRub")
        TableColumn("Итого ₽") { (r: HistoryRow) in Cell.money(r.totalRUB, bold: true) }
          .width(min: 110, ideal: 130)
          .alignment(.trailing)
          .customizationID("totalRub")
        TableColumn("Δ ₽") { (r: HistoryRow) in Cell.delta(r.deltaRUB?.value) }
          .width(min: 100, ideal: 115)
          .alignment(.trailing)
          .customizationID("dRub")
      }
      Group {
        TableColumn("Δ ₽/день") { (r: HistoryRow) in Cell.delta(r.deltaRUB?.perDay) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dRubDay")
        TableColumn("Итого $") { (r: HistoryRow) in Cell.money(r.totalUSD, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalUsd")
        TableColumn("Δ $") { (r: HistoryRow) in Cell.delta(r.deltaUSD?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dUsd")
        TableColumn("Δ $/день") { (r: HistoryRow) in Cell.delta(r.deltaUSD?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dUsdDay")
        TableColumn("Итого €") { (r: HistoryRow) in Cell.money(r.totalEUR, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalEur")
        TableColumn("Δ €") { (r: HistoryRow) in Cell.delta(r.deltaEUR?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dEur")
        TableColumn("Δ €/день") { (r: HistoryRow) in Cell.delta(r.deltaEUR?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dEurDay")
      }
    } rows: {
      ForEach(rows)
    }
    .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
      if let id = ids.first, ids.count == 1 {
        Button("Открыть") { path.append(id) }
      }
      if !ids.isEmpty {
        Button("Удалить", role: .destructive) { pendingDelete = ids }
      }
    } primaryAction: { ids in
      if let id = ids.first { path.append(id) }
    }
  }

  private func delete(_ ids: Set<PersistentIdentifier>) {
    for snapshot in snapshots where ids.contains(snapshot.persistentModelID) {
      context.delete(snapshot)
    }
    try? context.save()
    selection.subtract(ids)
    pendingDelete = []
  }
}

/// Table cell styles for the history table.
private enum Cell {
  static func money(_ value: Double?, bold: Bool = false) -> some View {
    Text(Fmt.money(value)).monospacedDigit().fontWeight(bold ? .semibold : .regular)
  }

  /// Orange when the rate was typed by hand or obtained for another day.
  static func rate(_ value: Double, needsAttention: Bool) -> some View {
    Text(Fmt.rate(value))
      .monospacedDigit()
      .foregroundStyle(needsAttention ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
      .help(needsAttention ? "Курс введён вручную или получен на другую дату" : "")
  }

  /// Green for growth, red for decline; blank when there is nothing to compare with.
  static func delta(_ value: Double?) -> some View {
    Text(value.map(Fmt.signedMoney) ?? "")
      .monospacedDigit()
      .foregroundStyle(value.map { $0 > 0 ? Color.green : $0 < 0 ? .red : .secondary } ?? .secondary)
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  return HistoryView()
    .modelContainer(container)
    .frame(width: 1100, height: 400)
}

#Preview("Пусто") {
  HistoryView()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
