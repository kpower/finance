import SwiftData
import SwiftUI

struct BalanceView: View {
  /// Screens pushed over the section's table; owned by `MainView`.
  @Binding var path: NavigationPath

  @Environment(\.modelContext) private var context
  @Query(sort: \Snapshot.date) private var snapshots: [Snapshot]

  @State private var selection: Set<PersistentIdentifier> = []
  @State private var pendingDelete: Set<PersistentIdentifier> = []
  @State private var isAddingArchive = false
  /// Changes when a selection is replaced from code, which builds the table anew: it keeps a row selected
  /// that was deselected from code while scrolled out of view, and its menu then acts on that row too.
  @State private var tableGeneration = 0
  @FocusState private var isTableFocused: Bool
  @SceneStorage("balanceColumns") private var customization = TableColumnCustomization<BalanceRow>()

  private var rows: [BalanceRow] { BalanceCalculator.rows(for: snapshots.map { Stored($0) }).reversed() }

  /// Deposits of the latest detailed entry, which a new entry starts from; empty when there is none.
  private var latestDeposits: [Deposit] {
    for snapshot in snapshots.reversed() {
      switch SnapshotValues(snapshot).content {
      case let .detailed(deposits): return deposits
      case .summaryOnly: continue
      }
    }
    return []
  }

  var body: some View {
    Group {
      if snapshots.isEmpty {
        ContentUnavailableView {
          Label { Text(.balanceEmptyTitle) } icon: { Image(systemName: "clock.arrow.circlepath") }
        } description: {
          Text(.balanceEmptyDescription)
        } actions: {
          Button { path.append(BalanceRoute.newEntry) } label: { Text(.balanceEmptyAddButton) }
            .buttonStyle(.borderedProminent)
        }
      } else {
        ScrollViewReader { scroll in
          VSplitView {
            BalanceCharts(rows: rows) { id in
              if !selection.isEmpty { tableGeneration += 1 }
              selection = [id]
              // Once the table has the selection: a table built in the same update loses both.
              DispatchQueue.main.async {
                scroll.scrollTo(id)
                // The arrow keys then move on from the picked row.
                isTableFocused = true
              }
            }
            .frame(minHeight: 180, idealHeight: 240)
            // The wrapper keeps the pane, and with it the divider, in place when the table is built anew.
            ZStack { table.id(tableGeneration) }
              .frame(minHeight: 160)
          }
        }
      }
    }
    .navigationTitle(Text(.balanceNavigationTitle))
    .toolbar {
      Button { path.append(BalanceRoute.newEntry) } label: {
        Label { Text(.balanceToolbarAddEntryButton) } icon: { Image(systemName: "plus") }
      }
      .help(Text(.balanceToolbarAddEntryHelp))
      Button { isAddingArchive = true } label: {
        Label { Text(.balanceToolbarAddArchiveButton) } icon: { Image(systemName: "archivebox") }
      }
      .help(Text(.balanceToolbarAddArchiveHelp))
    }
    .sheet(isPresented: $isAddingArchive) {
      ArchiveEntrySheet()
    }
    .navigationDestination(for: BalanceRoute.self) { route in
      switch route {
      case .newEntry:
        SnapshotDetailView(newEntryWith: latestDeposits)
      case let .entry(id):
        if let snapshot = snapshots.first(where: { $0.persistentModelID == id }) {
          SnapshotDetailView(snapshot: snapshot)
        } else {
          ContentUnavailableView {
            Label { Text(.balanceDetailDeletedTitle) } icon: { Image(systemName: "trash") }
          }
        }
      }
    }
    .confirmationDialog(
      Text(.balanceDeleteDialogTitle),
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button(role: .destructive) { delete(pendingDelete) } label: { Text(.balanceDeleteDialogDeleteButton) }
    } message: {
      Text(.balanceDeleteDialogMessage(pendingDelete.count))
    }
  }

  private var table: some View {
    Table(of: BalanceRow.self, selection: $selection, columnCustomization: $customization) {
      Group {
        TableColumn(Text(.balanceTableDateColumn)) { (row: BalanceRow) in
          HStack(spacing: 4) {
            Text(Fmt.date(row.date)).monospacedDigit()
            switch row.kind {
            case .detailed:
              EmptyView()
            case .summaryOnly:
              Image(systemName: "archivebox")
                .foregroundStyle(.secondary)
                .help(Text(.balanceTableArchiveEntryHelp))
            }
          }
        }
          .width(min: 100, ideal: 110)
          .customizationID("date")
        TableColumn(Text(verbatim: "₽")) { (r: BalanceRow) in Cell.money(r.sumRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("rub")
        TableColumn(Text(verbatim: "$")) { (r: BalanceRow) in Cell.money(r.sumUSD) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("usd")
        TableColumn(Text(.balanceTableUsdRateColumn)) { (r: BalanceRow) in Cell.rate(r.usdRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("usdRate")
        TableColumn(Text(.balanceTableUsdInRubColumn)) { (r: BalanceRow) in Cell.money(r.usdInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("usdInRub")
        TableColumn(Text(verbatim: "€")) { (r: BalanceRow) in Cell.money(r.sumEUR) }
          .width(min: 90, ideal: 110)
          .alignment(.trailing)
          .customizationID("eur")
        TableColumn(Text(.balanceTableEurRateColumn)) { (r: BalanceRow) in Cell.rate(r.eurRate, needsAttention: r.ratesNeedAttention) }
          .width(min: 70, ideal: 80)
          .alignment(.trailing)
          .customizationID("eurRate")
        TableColumn(Text(.balanceTableEurInRubColumn)) { (r: BalanceRow) in Cell.money(r.eurInRUB) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("eurInRub")
        TableColumn(Text(.balanceTableTotalRubColumn)) { (r: BalanceRow) in Cell.money(r.totalRUB, bold: true) }
          .width(min: 110, ideal: 130)
          .alignment(.trailing)
          .customizationID("totalRub")
        TableColumn(Text(verbatim: "Δ ₽")) { (r: BalanceRow) in Cell.delta(r.deltaRUB?.value) }
          .width(min: 100, ideal: 115)
          .alignment(.trailing)
          .customizationID("dRub")
      }
      Group {
        TableColumn(Text(.balanceTableDeltaRubPerDayColumn)) { (r: BalanceRow) in Cell.delta(r.deltaRUB?.perDay) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dRubDay")
        TableColumn(Text(.balanceTableTotalUsdColumn)) { (r: BalanceRow) in Cell.money(r.totalUSD, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalUsd")
        TableColumn(Text(verbatim: "Δ $")) { (r: BalanceRow) in Cell.delta(r.deltaUSD?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dUsd")
        TableColumn(Text(.balanceTableDeltaUsdPerDayColumn)) { (r: BalanceRow) in Cell.delta(r.deltaUSD?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dUsdDay")
        TableColumn(Text(.balanceTableTotalEurColumn)) { (r: BalanceRow) in Cell.money(r.totalEUR, bold: true) }
          .width(min: 100, ideal: 120)
          .alignment(.trailing)
          .customizationID("totalEur")
        TableColumn(Text(verbatim: "Δ €")) { (r: BalanceRow) in Cell.delta(r.deltaEUR?.value) }
          .width(min: 90, ideal: 105)
          .alignment(.trailing)
          .customizationID("dEur")
        TableColumn(Text(.balanceTableDeltaEurPerDayColumn)) { (r: BalanceRow) in Cell.delta(r.deltaEUR?.perDay) }
          .width(min: 80, ideal: 95)
          .alignment(.trailing)
          .customizationID("dEurDay")
        TableColumn(Text(.balanceTableCommentColumn)) { (r: BalanceRow) in
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
        Button { path.append(BalanceRoute.entry(id)) } label: { Text(.balanceContextMenuOpenButton) }
      }
      if !ids.isEmpty {
        Button(role: .destructive) { pendingDelete = ids } label: { Text(.balanceContextMenuDeleteButton) }
      }
    } primaryAction: { ids in
      if let id = ids.first { path.append(BalanceRoute.entry(id)) }
    }
    .onDeleteCommand { pendingDelete = selection }
    .focused($isTableFocused)
    // Coming back from a pushed screen leaves nothing focused, and so can a click on a row: the selection
    // then turns gray and the arrow keys do nothing.
    .onChange(of: selection) { isTableFocused = true }
    .onChange(of: path.isEmpty) { if path.isEmpty { isTableFocused = true } }
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

/// Screens pushed over the balance table.
private enum BalanceRoute: Hashable {
  case entry(PersistentIdentifier)
  /// A detailed entry that does not exist until it is saved from its screen.
  case newEntry
}

extension Cell {
  /// Orange when the rate was typed by hand or obtained for another day.
  fileprivate static func rate(_ value: Double, needsAttention: Bool) -> some View {
    Text(Fmt.rate(value))
      .monospacedDigit()
      .foregroundStyle(needsAttention ? AnyShapeStyle(.orange) : AnyShapeStyle(.secondary))
      .help(needsAttention ? Text(.balanceTableRateAttentionHelp) : Text(verbatim: ""))
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  return NavigationStack { BalanceView(path: .constant(NavigationPath())) }
    .modelContainer(container)
    .frame(width: 1100, height: 400)
}

#Preview("Empty") {
  NavigationStack { BalanceView(path: .constant(NavigationPath())) }
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
