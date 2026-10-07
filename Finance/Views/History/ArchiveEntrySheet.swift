import SwiftData
import SwiftUI

/// Adds a past history entry with only currency totals (no per-deposit details).
struct ArchiveEntrySheet: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  @State private var date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
  @State private var rub: Double?
  @State private var usd: Double?
  @State private var eur: Double?
  @State private var comment = ""
  @State private var rates = Rates(usd: 0, eur: 0, date: nil, source: RateSource.manual)
  @State private var ratesRequestedFor: Date?

  private var isDayTaken: Bool { SnapshotService.isDayTaken(date, in: context) }
  private var hasAmounts: Bool { (rub ?? 0) != 0 || (usd ?? 0) != 0 || (eur ?? 0) != 0 }
  private var hasRates: Bool { rates.usd > 0 && rates.eur > 0 }
  private var ratesNeedAttention: Bool {
    Snapshot.ratesNeedAttention(source: rates.source, requestedFor: ratesRequestedFor, date: date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text(.archiveEntryHeaderTitle).font(.title2.weight(.semibold))
      Text(.archiveEntryHeaderDescription)
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
          Text(.archiveEntryFormDateLabel).gridColumnAlignment(.trailing)
          HStack(spacing: 8) {
            DatePicker(selection: $date, in: ...Date.now, displayedComponents: .date) {
              Text(.archiveEntryFormDateLabel)
            }
            .labelsHidden()
            .datePickerStyle(.field)
              .fixedSize()
            if isDayTaken {
              Text(.archiveEntryFormDateTakenError).foregroundStyle(.red)
            }
          }
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text(.archiveEntryFormRubLabel)
          amountField(.archiveEntryFormRubLabel, $rub)
        }
        GridRow {
          Text(.archiveEntryFormUsdLabel)
          amountField(.archiveEntryFormUsdLabel, $usd)
        }
        GridRow {
          Text(.archiveEntryFormEurLabel)
          amountField(.archiveEntryFormEurLabel, $eur)
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text(.archiveEntryFormRatesLabel)
          SnapshotRatesEditor(date: date, rates: rates, needsAttention: ratesNeedAttention) { newRates, day in
            rates = newRates
            ratesRequestedFor = day
          }
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text(.archiveEntryFormCommentLabel)
          TextField(text: $comment) { Text(.archiveEntryFormCommentLabel) }
            .labelsHidden()
        }
      }

      Spacer(minLength: 0)
      HStack {
        Spacer()
        Button { dismiss() } label: { Text(.archiveEntryFooterCancelButton) }
          .keyboardShortcut(.cancelAction)
        Button(action: save) { Text(.archiveEntryFooterAddButton) }
          .keyboardShortcut(.defaultAction)
          .disabled(isDayTaken || !hasAmounts || !hasRates)
      }
    }
    .padding(20)
    .frame(minWidth: 600, idealWidth: 640, maxWidth: .infinity, minHeight: 420, idealHeight: 440, maxHeight: .infinity)
  }

  private func amountField(_ title: LocalizedStringResource, _ value: Binding<Double?>) -> some View {
    TextField(String(localized: title), value: value, format: Fmt.moneyInput, prompt: Text(verbatim: "0"))
      .labelsHidden()
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
      .frame(width: 180)
  }

  private func save() {
    let snapshot = Snapshot(date: date, rates: rates, rub: rub ?? 0, usd: usd ?? 0, eur: eur ?? 0)
    snapshot.setRates(rates, requestedFor: ratesRequestedFor)
    snapshot.comment = comment.trimmingCharacters(in: .whitespacesAndNewlines)
    context.insert(snapshot)
    try? context.save()
    dismiss()
  }
}

#Preview {
  ArchiveEntrySheet()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
