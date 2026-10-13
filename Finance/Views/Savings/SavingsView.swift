import SwiftData
import SwiftUI

struct SavingsView: View {
  /// Screens pushed over the section's table; owned by `MainView`.
  @Binding var path: NavigationPath

  @Environment(\.modelContext) private var context
  @Query(sort: \SavingsEntry.date) private var entries: [SavingsEntry]
  @Query private var years: [SavingsYear]
  @Query private var inflation: [AnnualInflation]

  @State private var selection: Set<PersistentIdentifier> = []
  @State private var pendingDelete: Set<PersistentIdentifier> = []
  @SceneStorage("savingsColumns") private var customization = TableColumnCustomization<SavingsRow>()

  private var rows: [SavingsRow] { SavingsPlan.rows(for: entries, years: years, inflation: inflation).reversed() }

  var body: some View {
    Group {
      if entries.isEmpty {
        ContentUnavailableView {
          Label { Text(.savingsEmptyTitle) } icon: { Image(systemName: "banknote") }
        } description: {
          Text(.savingsEmptyDescription)
        } actions: {
          Button { path.append(SavingsRoute.newEntry) } label: { Text(.savingsEmptyAddButton) }
            .buttonStyle(.borderedProminent)
        }
      } else {
        table
      }
    }
    .navigationTitle(Text(.savingsNavigationTitle))
    .toolbar {
      Button { path.append(SavingsRoute.newEntry) } label: {
        Label { Text(.savingsToolbarAddEntryButton) } icon: { Image(systemName: "plus") }
      }
      .help(Text(.savingsToolbarAddEntryHelp))
      Button(action: openYears) {
        Label { Text(.savingsToolbarYearsButton) } icon: { Image(systemName: "calendar") }
      }
      .help(Text(.savingsToolbarYearsHelp))
    }
    .navigationDestination(for: SavingsRoute.self) { route in
      switch route {
      case .newEntry:
        SavingsEntryDetailView(newEntryAfter: entries.last, openYears: openYears)
      case let .entry(id):
        if let entry = entries.first(where: { $0.persistentModelID == id }) {
          SavingsEntryDetailView(entry: entry, openYears: openYears)
        } else {
          ContentUnavailableView {
            Label { Text(.savingsDetailDeletedTitle) } icon: { Image(systemName: "trash") }
          }
        }
      case .years:
        SavingsYearsView()
      }
    }
    .confirmationDialog(
      Text(.savingsDeleteDialogTitle),
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button(role: .destructive) { delete(pendingDelete) } label: { Text(.savingsDeleteDialogDeleteButton) }
    } message: {
      Text(.savingsDeleteDialogMessage(pendingDelete.count))
    }
  }

  private var table: some View {
    Table(of: SavingsRow.self, selection: $selection, columnCustomization: $customization) {
      TableColumn(Text(.savingsTableDateColumn)) { (row: SavingsRow) in
        HStack(spacing: 4) {
          Text(Fmt.date(row.date)).monospacedDigit()
          switch row.outcome {
          case .figures:
            EmptyView()
          case let .missing(gap):
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)
              .help(Text(gap.message))
          }
        }
      }
        .width(min: 100, ideal: 110)
        .customizationID("date")
      TableColumn(Text(.savingsTableGrossColumn)) { (r: SavingsRow) in Cell.money(r.grossMonthly) }
        .width(min: 100, ideal: 120)
        .alignment(.trailing)
        .customizationID("gross")
      TableColumn(Text(.savingsTableNetColumn)) { (r: SavingsRow) in Cell.money(r.outcome.figures?.net) }
        .width(min: 100, ideal: 120)
        .alignment(.trailing)
        .customizationID("net")
      TableColumn(Text(.savingsTableExpensesColumn)) { (r: SavingsRow) in
        Cell.money(r.expenses.total).help(Text(verbatim: Self.breakdown(of: r.expenses)))
      }
        .width(min: 100, ideal: 120)
        .alignment(.trailing)
        .customizationID("expenses")
      TableColumn(Text(.savingsTableStartMoneyColumn)) { (r: SavingsRow) in Cell.money(r.outcome.figures?.startMoney) }
        .width(min: 100, ideal: 130)
        .alignment(.trailing)
        .customizationID("startMoney")
      TableColumn(Text(verbatim: "Δ")) { (r: SavingsRow) in Cell.money(r.outcome.figures?.delta) }
        .width(min: 100, ideal: 120)
        .alignment(.trailing)
        .customizationID("delta")
      TableColumn(Text(.savingsTableSavedShareColumn)) { (r: SavingsRow) in Cell.money(r.outcome.figures?.savedShare) }
        .width(min: 90, ideal: 110)
        .alignment(.trailing)
        .customizationID("savedShare")
      TableColumn(Text(.savingsTableSaveMonthlyColumn)) { (r: SavingsRow) in Cell.delta(r.outcome.figures?.saveMonthly) }
        .width(min: 100, ideal: 120)
        .alignment(.trailing)
        .customizationID("saveMonthly")
      TableColumn(Text(.savingsTableCommentColumn)) { (r: SavingsRow) in
        Text(r.comment).lineLimit(1).help(Text(verbatim: r.comment))
      }
        .width(min: 120, ideal: 260)
        .customizationID("comment")
    } rows: {
      ForEach(rows)
    }
    .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
      if let id = ids.first, ids.count == 1 {
        Button { path.append(SavingsRoute.entry(id)) } label: { Text(.savingsContextMenuOpenButton) }
      }
      if !ids.isEmpty {
        Button(role: .destructive) { pendingDelete = ids } label: { Text(.savingsContextMenuDeleteButton) }
      }
    } primaryAction: { ids in
      if let id = ids.first { path.append(SavingsRoute.entry(id)) }
    }
  }

  /// One block per line, a split one followed by its parts: "Mortgage: 96 000 = principal 78 000 + interest 18 000".
  private static func breakdown(of expenses: [ExpenseBlock]) -> String {
    expenses.map { block in
      let total = "\(block.name): \(Fmt.money(block.total))"
      switch block.content {
      case .single:
        return total
      case let .split(parts):
        return total + " = " + parts.map { "\($0.name) \(Fmt.money($0.amount))" }.joined(separator: " + ")
      }
    }
    .joined(separator: "\n")
  }

  private func openYears() {
    path.append(SavingsRoute.years)
  }

  private func delete(_ ids: Set<PersistentIdentifier>) {
    for entry in entries where ids.contains(entry.persistentModelID) {
      context.delete(entry)
    }
    try? context.save()
    selection.subtract(ids)
    pendingDelete = []
  }
}

/// Screens pushed over the savings table.
private enum SavingsRoute: Hashable {
  case entry(PersistentIdentifier)
  /// An entry that does not exist until it is saved from its screen.
  case newEntry
  case years
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  return NavigationStack { SavingsView(path: .constant(NavigationPath())) }
    .modelContainer(container)
    .frame(width: 1100, height: 400)
}

#Preview("Empty") {
  NavigationStack { SavingsView(path: .constant(NavigationPath())) }
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
