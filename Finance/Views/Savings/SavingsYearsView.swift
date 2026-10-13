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
      SavingsYearSheet(after: years.first)
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
    let plan = SavingsPlan(entries: entries.map(\.input), years: years, inflation: inflation)
    return Table(years, selection: $selection) {
      TableColumn(Text(.savingsYearsTableYearColumn)) { year in
        Text(verbatim: String(year.year)).monospacedDigit()
      }
      .width(min: 50, ideal: 60)

      TableColumn(Text(.savingsYearsTableLifeLevelUpColumn)) { year in
        PercentCell(value: Bindable(year).lifeLevelUp)
      }
      .width(min: 80, ideal: 130)
      .alignment(.trailing)

      TableColumn(Text(.savingsYearsTableBaseTaxColumn)) { year in
        PercentCell(value: Bindable(year).baseTaxRate)
      }
      .width(min: 70, ideal: 90)
      .alignment(.trailing)

      TableColumn(Text(.savingsYearsTableHigherTaxColumn)) { year in
        HigherTaxCell(year: year)
      }
      .width(min: 200, ideal: 380)

      TableColumn(Text(.savingsYearsTableStartMoneyColumn)) { year in
        Cell.money(plan?.startMoneyAtEnd(of: year.year))
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
  @Bindable var year: SavingsYear
  @State private var isEditing = false

  private var summary: String {
    year.higherTaxBrackets
      .sorted { $0.threshold < $1.threshold }
      .map { String(localized: .savingsYearsBracketSummary(Fmt.percent($0.rate), Fmt.compactMoney($0.threshold))) }
      .joined(separator: " · ")
  }

  var body: some View {
    HStack(spacing: 4) {
      if year.higherTaxBrackets.isEmpty {
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
        TaxBracketsEditor(brackets: $year.higherTaxBrackets)
      }
    }
  }
}

private struct TaxBracketsEditor: View {
  @Binding var brackets: [TaxBracket]

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
