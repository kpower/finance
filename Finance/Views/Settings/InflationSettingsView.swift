import SwiftData
import SwiftUI

/// Official inflation by year, which the savings calculation raises the start money with.
struct InflationSettingsView: View {
  @Environment(\.modelContext) private var context
  @Query(sort: \AnnualInflation.year, order: .reverse) private var years: [AnnualInflation]

  @State private var selection: Set<PersistentIdentifier> = []
  @State private var pendingDelete: Set<PersistentIdentifier> = []
  @State private var isAdding = false
  @State private var editing: AnnualInflation?

  private var rows: [Stored<AnnualInflationValues>] { years.map { Stored($0) } }

  private var selectedYear: AnnualInflation? {
    selection.count == 1 ? years.first { selection.contains($0.persistentModelID) } : nil
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(.settingsInflationDescription)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      table
      HStack {
        Button { isAdding = true } label: { Text(.settingsInflationAddButton) }
        Button { editing = selectedYear } label: { Text(.settingsInflationEditButton) }
          .disabled(selectedYear == nil)
        Button { pendingDelete = selection } label: { Text(.settingsInflationDeleteButton) }
          .disabled(selection.isEmpty)
      }
    }
    .padding(20)
    .sheet(isPresented: $isAdding) {
      InflationYearSheet(addingAfter: rows.first?.values)
    }
    .sheet(item: $editing) { year in
      InflationYearSheet(editing: year)
    }
    .confirmationDialog(
      Text(.settingsInflationDeleteDialogTitle),
      isPresented: Binding(get: { !pendingDelete.isEmpty }, set: { if !$0 { pendingDelete = [] } }),
      titleVisibility: .visible
    ) {
      Button(role: .destructive) { delete(pendingDelete) } label: { Text(.settingsInflationDeleteDialogDeleteButton) }
    } message: {
      Text(.settingsInflationDeleteDialogMessage)
    }
  }

  private var table: some View {
    Table(rows, selection: $selection) {
      TableColumn(Text(.inflationFormYearLabel)) { row in
        Text(verbatim: String(row.values.year)).monospacedDigit()
      }
      TableColumn(Text(.inflationFormPercentLabel)) { row in
        Text(Fmt.percent(row.values.percent)).monospacedDigit()
      }
      .alignment(.trailing)
    }
    .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
      if let id = ids.first, ids.count == 1 {
        Button { edit(id) } label: { Text(.settingsInflationEditButton) }
      }
      if !ids.isEmpty {
        Button(role: .destructive) { pendingDelete = ids } label: { Text(.settingsInflationDeleteButton) }
      }
    } primaryAction: { ids in
      if let id = ids.first { edit(id) }
    }
    .onDeleteCommand { pendingDelete = selection }
    .frame(height: 280)
  }

  private func edit(_ id: PersistentIdentifier) {
    editing = years.first { $0.persistentModelID == id }
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

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  return InflationSettingsView()
    .modelContainer(container)
    .frame(width: 460)
}
