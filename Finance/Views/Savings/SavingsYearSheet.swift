import SwiftData
import SwiftUI

/// Adds the parameters of a year, starting from those of the latest year.
struct SavingsYearSheet: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Query private var years: [SavingsYear]

  @State private var year: Int?
  @State private var lifeLevelUp: Double?
  @State private var baseTaxRate: Double?
  /// Copied from the latest year; edited in the table once the year is added.
  private let higherTaxBrackets: [TaxBracket]

  init(after latest: SavingsYear?) {
    _year = State(initialValue: latest.map { $0.year + 1 })
    _lifeLevelUp = State(initialValue: latest?.lifeLevelUp)
    _baseTaxRate = State(initialValue: latest?.baseTaxRate)
    higherTaxBrackets = latest?.higherTaxBrackets ?? []
  }

  private var isYearTaken: Bool { years.contains { $0.year == year } }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(.savingsYearSheetTitle).font(.title2.weight(.semibold))
      Text(.savingsYearSheetDescription)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
          Text(.savingsYearsTableYearColumn).gridColumnAlignment(.trailing)
          HStack(spacing: 8) {
            TextField(value: $year, format: .number.grouping(.never)) { Text(.savingsYearsTableYearColumn) }
              .labelsHidden()
              .multilineTextAlignment(.trailing)
              .monospacedDigit()
              .frame(width: 120)
            if isYearTaken {
              Text(.savingsYearSheetYearTakenError).foregroundStyle(.red)
            }
          }
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text(.savingsYearsTableLifeLevelUpColumn)
          percentField(.savingsYearsTableLifeLevelUpColumn, $lifeLevelUp)
        }
        GridRow {
          Text(.savingsYearsTableBaseTaxColumn)
          percentField(.savingsYearsTableBaseTaxColumn, $baseTaxRate)
        }
      }

      Spacer(minLength: 0)
      HStack {
        Spacer()
        Button { dismiss() } label: { Text(.savingsYearSheetCancelButton) }
          .keyboardShortcut(.cancelAction)
        Button(action: save) { Text(.savingsYearSheetAddButton) }
          .keyboardShortcut(.defaultAction)
          .disabled(isYearTaken || year == nil || lifeLevelUp == nil || baseTaxRate == nil)
      }
    }
    .padding(20)
    .frame(minWidth: 460, idealWidth: 480, minHeight: 260, idealHeight: 280)
  }

  private func percentField(_ title: LocalizedStringResource, _ value: Binding<Double?>) -> some View {
    TextField(String(localized: title), value: value, format: Fmt.moneyInput)
      .labelsHidden()
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
      .frame(width: 120)
  }

  private func save() {
    guard let year, let lifeLevelUp, let baseTaxRate else { return }
    context.insert(SavingsYear(
      year: year, lifeLevelUp: lifeLevelUp, baseTaxRate: baseTaxRate,
      higherTaxBrackets: higherTaxBrackets
    ))
    try? context.save()
    dismiss()
  }
}

#Preview {
  SavingsYearSheet(after: nil)
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
