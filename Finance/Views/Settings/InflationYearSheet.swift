import SwiftData
import SwiftUI

/// Adds the inflation of a year or changes a stored one.
struct InflationYearSheet: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Query private var years: [AnnualInflation]

  /// Year being changed; nil when a year is added.
  private let stored: AnnualInflation?
  @State private var year: Int?
  @State private var percent: Double?

  /// A new year, the one after `latest`.
  init(addingAfter latest: AnnualInflation?) {
    stored = nil
    _year = State(initialValue: latest.map { $0.year + 1 })
    _percent = State(initialValue: nil)
  }

  init(editing stored: AnnualInflation) {
    self.stored = stored
    _year = State(initialValue: stored.year)
    _percent = State(initialValue: stored.percent)
  }

  private var isYearTaken: Bool {
    stored == nil && years.contains { $0.year == year }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      title.font(.title2.weight(.semibold))
      Text(.inflationFormDescription)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)
      Link(destination: sourceURL) {
        Label { Text(.inflationFormSourceLink) } icon: { Image(systemName: "arrow.up.right.square") }
      }

      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
        if stored == nil {
          GridRow {
            Text(.inflationFormYearLabel).gridColumnAlignment(.trailing)
            HStack(spacing: 8) {
              TextField(value: $year, format: .number.grouping(.never)) { Text(.inflationFormYearLabel) }
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(width: 120)
              if isYearTaken {
                Text(.inflationFormYearTakenError).foregroundStyle(.red)
              }
            }
          }
        }
        GridRow {
          Text(.inflationFormPercentLabel).gridColumnAlignment(.trailing)
          TextField(value: $percent, format: Fmt.moneyInput) { Text(.inflationFormPercentLabel) }
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 120)
        }
      }

      Spacer(minLength: 0)
      HStack {
        Spacer()
        Button { dismiss() } label: { Text(.inflationFormCancelButton) }
          .keyboardShortcut(.cancelAction)
        Button(action: save) {
          Text(stored == nil ? LocalizedStringResource.inflationFormAddButton : .inflationFormSaveButton)
        }
        .keyboardShortcut(.defaultAction)
        .disabled(isYearTaken || year == nil || percent == nil)
      }
    }
    .padding(20)
    .frame(minWidth: 420, idealWidth: 440, minHeight: 280, idealHeight: 300)
  }

  private var title: Text {
    if let stored {
      Text(.inflationFormEditTitle(String(stored.year)))
    } else {
      Text(.inflationFormAddTitle)
    }
  }

  private func save() {
    guard let year, let percent else { return }
    if let stored {
      stored.percent = percent
    } else {
      context.insert(AnnualInflation(year: year, percent: percent))
    }
    try? context.save()
    dismiss()
  }
}

/// Bank of Russia's table of inflation by month, year over year.
private let sourceURL = URL(string: "https://www.cbr.ru/hd_base/infl/")!

#Preview {
  InflationYearSheet(addingAfter: nil)
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
