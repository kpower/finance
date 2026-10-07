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
          ContentUnavailableView {
            Label { Text(.historyEmptyTitle) } icon: { Image(systemName: "clock.arrow.circlepath") }
          } description: {
            Text(.historyEmptyDescription)
          }
        } else {
          VSplitView {
            HistoryCharts(rows: rows)
              .frame(minHeight: 180, idealHeight: 240)
            table
              .frame(minHeight: 160)
          }
        }
      }
      .navigationTitle(Text(.historyNavigationTitle))
      .toolbar {
        Button { isAddingArchive = true } label: {
          Label { Text(.historyToolbarAddArchiveButton) } icon: { Image(systemName: "archivebox") }
        }
        .help(Text(.historyToolbarAddArchiveHelp))
      }
      .sheet(isPresented: $isAddingArchive) {
        ArchiveEntrySheet()
      }
      .navigationDestination(for: PersistentIdentifier.self) { id in
        if let snapshot = snapshots.first(where: { $0.persistentModelID == id }) {
          SnapshotDetailView(snapshot: snapshot)
        } else {
          ContentUnavailableView {
            Label { Text(.historyDetailDeletedTitle) } icon: { Image(systemName: "trash") }
          }
        }
      }
    }
    .confirmationDialog(
      Text(.historyDeleteDialogTitle),
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button(role: .destructive) { delete(pendingDelete) } label: { Text(.historyDeleteDialogDeleteButton) }
    } message: {
      Text(.historyDeleteDialogMessage(pendingDelete.count))
    }
  }

  private var table: some View {
    Table(of: HistoryRow.self, selection: $selection, columnCustomization: $customization) {
      Group {
        TableColumn(Text(.historyTableDateColumn)) { (row: HistoryRow) in
          HStack(spacing: 4) {
            Text(Fmt.date(row.date)).monospacedDigit()
            if row.isSummaryOnly {
              Image(systemName: "archivebox")
                .foregroundStyle(.secondary)
                .help(Text(.historyTableArchiveEntryHelp))
            }
          }
        }
          .width(min: 100, ideal: 110)
          .customizationID("date")
        TableColumn(Text(verbatim: "₽")) { (r: HistoryRow) in Cell.money(r.sumRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("rub")
        TableColumn(Text(verbatim: "$")) { (r: HistoryRow) in Cell.money(r.sumUSD) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("usd")
        TableColumn(Text(.historyTableUsdRateColumn)) { (r: HistoryRow) in Cell.rate(r.usdRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("usdRate")
        TableColumn(Text(.historyTableUsdInRubColumn)) { (r: HistoryRow) in Cell.money(r.usdInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("usdInRub")
        TableColumn(Text(verbatim: "€")) { (r: HistoryRow) in Cell.money(r.sumEUR) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("eur")
        TableColumn(Text(.historyTableEurRateColumn)) { (r: HistoryRow) in Cell.rate(r.eurRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("eurRate")
        TableColumn(Text(.historyTableEurInRubColumn)) { (r: HistoryRow) in Cell.money(r.eurInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("eurInRub")
        TableColumn(Text(.historyTableTotalRubColumn)) { (r: HistoryRow) in Cell.money(r.totalRUB, bold: true) }
          .width(min: 110, ideal: 130)
          .alignment(.trailing)
          .customizationID("totalRub")
        TableColumn(Text(verbatim: "Δ ₽")) { (r: HistoryRow) in Cell.delta(r.deltaRUB?.value) }
          .width(min: 100, ideal: 115)
          .alignment(.trailing)
          .customizationID("dRub")
      }
      Group {
        TableColumn(Text(.historyTableDeltaRubPerDayColumn)) { (r: HistoryRow) in Cell.delta(r.deltaRUB?.perDay) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dRubDay")
        TableColumn(Text(.historyTableTotalUsdColumn)) { (r: HistoryRow) in Cell.money(r.totalUSD, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalUsd")
        TableColumn(Text(verbatim: "Δ $")) { (r: HistoryRow) in Cell.delta(r.deltaUSD?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dUsd")
        TableColumn(Text(.historyTableDeltaUsdPerDayColumn)) { (r: HistoryRow) in Cell.delta(r.deltaUSD?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dUsdDay")
        TableColumn(Text(.historyTableTotalEurColumn)) { (r: HistoryRow) in Cell.money(r.totalEUR, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalEur")
        TableColumn(Text(verbatim: "Δ €")) { (r: HistoryRow) in Cell.delta(r.deltaEUR?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dEur")
        TableColumn(Text(.historyTableDeltaEurPerDayColumn)) { (r: HistoryRow) in Cell.delta(r.deltaEUR?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dEurDay")
        TableColumn(Text(.historyTableCommentColumn)) { (r: HistoryRow) in
          Text(r.comment).lineLimit(1).help(Text(verbatim: r.comment))
        }
          .width(min: 120, ideal: 260)
          .customizationID("comment")
      }
    } rows: {
      ForEach(rows)
    }
    .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
      if let id = ids.first, ids.count == 1 {
        Button { path.append(id) } label: { Text(.historyContextMenuOpenButton) }
      }
      if !ids.isEmpty {
        Button(role: .destructive) { pendingDelete = ids } label: { Text(.historyContextMenuDeleteButton) }
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
  fileprivate static func money(_ value: Double?, bold: Bool = false) -> some View {
    Text(Fmt.money(value)).monospacedDigit().fontWeight(bold ? .semibold : .regular)
  }

  /// Orange when the rate was typed by hand or obtained for another day.
  fileprivate static func rate(_ value: Double, needsAttention: Bool) -> some View {
    Text(Fmt.rate(value))
      .monospacedDigit()
      .foregroundStyle(needsAttention ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
      .help(needsAttention ? Text(.historyTableRateAttentionHelp) : Text(verbatim: ""))
  }

  /// Green for growth, red for decline; blank when there is nothing to compare with.
  fileprivate static func delta(_ value: Double?) -> some View {
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

#Preview("Empty") {
  HistoryView()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
