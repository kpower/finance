import SwiftData
import SwiftUI

/// Year parameters of the savings calculation. Unlike entries, they are edited in place:
/// a change is stored at once and every entry is recalculated with it.
struct SavingsYearsView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Query(sort: \SavingsYear.year, order: .reverse) private var years: [SavingsYear]
  @Query private var entries: [SavingsEntry]
  @Query private var inflation: [AnnualInflation]

  @State private var selection: Set<PersistentIdentifier> = []
  @State private var pendingDelete: Set<PersistentIdentifier> = []
  @State private var isAdding = false

  var body: some View {
    Group {
      if years.isEmpty {
        ContentUnavailableView {
          Label { Text(.savingsYearsEmptyTitle) } icon: { Image(systemName: "calendar") }
        } description: {
          Text(.savingsYearsEmptyDescription)
        } actions: {
          Button { isAdding = true } label: { Text(.savingsYearsEmptyAddButton) }
            .buttonStyle(.borderedProminent)
        }
      } else {
        table
      }
    }
    .navigationTitle(Text(.savingsYearsTitle))
    // Pushed over an entry screen, which hides the system back button, this screen gets none
    // either, so it has its own.
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button { dismiss() } label: {
          Label { Text(.savingsYearsToolbarBackButton) } icon: { Image(systemName: "chevron.backward") }
        }
      }
      ToolbarItemGroup {
        Button { isAdding = true } label: {
          Label { Text(.savingsYearsToolbarAddButton) } icon: { Image(systemName: "plus") }
        }
        .help(Text(.savingsYearsToolbarAddHelp))
        Button { pendingDelete = selection } label: {
          Label { Text(.savingsYearsToolbarDeleteButton) } icon: { Image(systemName: "trash") }
        }
        .disabled(selection.isEmpty)
      }
    }
    .sheet(isPresented: $isAdding) {
      SavingsYearSheet(after: years.first.map { SavingsYearValues($0) })
    }
    .confirmationDialog(
      Text(.savingsYearsDeleteDialogTitle),
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button(role: .destructive) { delete(pendingDelete) } label: { Text(.savingsYearsDeleteDialogDeleteButton) }
    } message: {
      Text(.savingsYearsDeleteDialogMessage)
    }
  }

  private var table: some View {
    let rows = years.map { Stored<SavingsYearValues>($0) }
    let plan = SavingsPlan(
      entries: entries.map { SavingsEntryValues($0) },
      years: rows.map(\.values),
      inflation: inflation.map { AnnualInflationValues($0) }
    )
    return Table(rows, selection: $selection) {
      TableColumn(Text(.savingsYearsTableYearColumn)) { row in
        Text(verbatim: String(row.values.year)).monospacedDigit()
      }
      .width(min: 50, ideal: 60)

      TableColumn(Text(.savingsYearsTableLifeLevelUpColumn)) { row in
        PercentCell(value: binding(to: row, \.lifeLevelUp))
      }
      .width(min: 80, ideal: 130)
      .alignment(.trailing)

      TableColumn(Text(.savingsYearsTableBaseTaxColumn)) { row in
        PercentCell(value: binding(to: row, \.baseTaxRate))
      }
      .width(min: 70, ideal: 90)
      .alignment(.trailing)

      TableColumn(Text(.savingsYearsTableHigherTaxColumn)) { row in
        HigherTaxCell(brackets: binding(to: row, \.higherTaxBrackets))
      }
      .width(min: 200, ideal: 380)

      TableColumn(Text(.savingsYearsTableStartMoneyColumn)) { row in
        Cell.money(plan?.startMoneyAtEnd(of: row.values.year))
      }
      .width(min: 110, ideal: 150)
      .alignment(.trailing)
    }
    .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
      if !ids.isEmpty {
        Button(role: .destructive) { pendingDelete = ids } label: { Text(.savingsYearsToolbarDeleteButton) }
      }
    }
    .onDeleteCommand { pendingDelete = selection }
  }

  /// Binding to a value of the year behind `row`; a change goes to the stored year at once.
  private func binding<Value>(
    to row: Stored<SavingsYearValues>, _ field: WritableKeyPath<SavingsYearValues, Value>
  ) -> Binding<Value> {
    Binding(
      get: { row.values[keyPath: field] },
      set: { newValue in
        guard let year = years.first(where: { $0.persistentModelID == row.id }) else { return }
        // The stored values as they are now: `row` may be older than another change of the year.
        var values = SavingsYearValues(year)
        values[keyPath: field] = newValue
        year.update(from: values)
      }
    )
  }

  private func delete(_ ids: Set<PersistentIdentifier>) {
    for year in years where ids.contains(year.persistentModelID) {
      context.delete(year)
    }
    try? context.save()
    selection.subtract(ids)
    pendingDelete = []
  }
}

// MARK: - Cells

private struct PercentCell: View {
  @Binding var value: Double

  var body: some View {
    TextField(value: $value, format: Fmt.moneyInput) { EmptyView() }
      .textFieldStyle(.plain)
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
  }
}

/// Raised tax rates of a year in one line, edited in a popover.
private struct HigherTaxCell: View {
  @Binding var brackets: [TaxBracket]
  @State private var isEditing = false

  private var summary: String {
    brackets
      .sorted { $0.threshold < $1.threshold }
      .map { String(localized: .savingsYearsBracketSummary(Fmt.percent($0.rate), Fmt.compactMoney($0.threshold))) }
      .joined(separator: " · ")
  }

  var body: some View {
    HStack(spacing: 4) {
      if brackets.isEmpty {
        Text(verbatim: "—").foregroundStyle(.tertiary)
      } else {
        Text(summary).lineLimit(1).help(Text(verbatim: summary))
      }
      Spacer(minLength: 0)
      Button { isEditing = true } label: {
        Label { Text(.savingsYearsBracketsEditButton) } icon: { Image(systemName: "pencil") }
      }
      .labelStyle(.iconOnly)
      .buttonStyle(.borderless)
      .foregroundStyle(.secondary)
      .help(Text(.savingsYearsBracketsEditButton))
      .popover(isPresented: $isEditing, arrowEdge: .bottom) {
        TaxBracketsEditor(brackets: brackets) { brackets = $0 }
      }
    }
  }
}

private struct TaxBracketsEditor: View {
  /// The editor's own copy. Brackets read from the store again have other ids, and a field
  /// must stay the same row while it is typed into.
  @State private var brackets: [TaxBracket]
  private let onChange: ([TaxBracket]) -> Void

  init(brackets: [TaxBracket], onChange: @escaping ([TaxBracket]) -> Void) {
    _brackets = State(initialValue: brackets)
    self.onChange = onChange
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Grid(alignment: .trailing, horizontalSpacing: 12, verticalSpacing: 8) {
        GridRow {
          Text(.savingsYearsBracketsThresholdLabel)
          Text(.savingsYearsBracketsRateLabel)
          Color.clear.gridCellUnsizedAxes([.horizontal, .vertical])
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        ForEach(brackets) { bracket in
          GridRow {
            numberField(binding(to: bracket).threshold).frame(width: 150)
            numberField(binding(to: bracket).rate).frame(width: 70)
            Button { brackets.removeAll { $0.id == bracket.id } } label: {
              Label { Text(.savingsYearsBracketsRemoveButton) } icon: { Image(systemName: "minus.circle") }
            }
            .labelStyle(.iconOnly)
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
            .help(Text(.savingsYearsBracketsRemoveButton))
          }
        }
      }
      Button {
        // A blank rate for the user to fill in.
        brackets.append(TaxBracket(threshold: 0, rate: 0))
      } label: {
        Text(.savingsYearsBracketsAddButton)
      }
    }
    .padding(16)
    .onChange(of: brackets) { onChange(brackets) }
  }

  private func numberField(_ value: Binding<Double>) -> some View {
    TextField(value: value, format: Fmt.moneyInput) { EmptyView() }
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
  }

  /// Reads fall back to `bracket` for the moment a field outlives its removed bracket.
  private func binding(to bracket: TaxBracket) -> Binding<TaxBracket> {
    Binding(
      get: { brackets.first { $0.id == bracket.id } ?? bracket },
      set: { newValue in
        guard let index = brackets.firstIndex(where: { $0.id == bracket.id }) else { return }
        brackets[index] = newValue
      }
    )
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  return NavigationStack {
    SavingsYearsView()
  }
  .modelContainer(container)
  .frame(width: 1000, height: 400)
}
