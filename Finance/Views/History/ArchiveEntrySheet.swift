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
  @State private var rates = Rates(usd: 0, eur: 0, date: nil, source: Rates.manualSource)
  @State private var ratesRequestedFor: Date?

  private var isDayTaken: Bool { SnapshotService.isDayTaken(date, in: context) }
  private var hasAmounts: Bool { (rub ?? 0) != 0 || (usd ?? 0) != 0 || (eur ?? 0) != 0 }
  private var hasRates: Bool { rates.usd > 0 && rates.eur > 0 }
  private var ratesNeedAttention: Bool {
    Snapshot.ratesNeedAttention(source: rates.source, requestedFor: ratesRequestedFor, date: date)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Архивная запись").font(.title2.weight(.semibold))
      Text("Хранит только итоговые суммы по валютам на дату, без распределения по вкладам.")
        .foregroundStyle(.secondary)
        .fixedSize(horizontal: false, vertical: true)

      Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 12) {
        GridRow {
          Text("Дата").gridColumnAlignment(.trailing)
          HStack(spacing: 8) {
            DatePicker("Дата", selection: $date, in: ...Date.now, displayedComponents: .date)
              .labelsHidden()
              .datePickerStyle(.field)
              .environment(\.locale, Fmt.ruLocale)
              .fixedSize()
            if isDayTaken {
              Text("На эту дату уже есть запись.").foregroundStyle(.red)
            }
          }
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text("Сумма, ₽")
          amountField("₽", $rub)
        }
        GridRow {
          Text("Сумма, $")
          amountField("$", $usd)
        }
        GridRow {
          Text("Сумма, €")
          amountField("€", $eur)
        }
        Divider().gridCellUnsizedAxes(.horizontal)
        GridRow {
          Text("Курсы")
          SnapshotRatesEditor(date: date, rates: rates, needsAttention: ratesNeedAttention) { newRates, day in
            rates = newRates
            ratesRequestedFor = day
          }
        }
      }

      Spacer(minLength: 0)
      HStack {
        Spacer()
        Button("Отмена") { dismiss() }
          .keyboardShortcut(.cancelAction)
        Button("Добавить", action: save)
          .keyboardShortcut(.defaultAction)
          .disabled(isDayTaken || !hasAmounts || !hasRates)
      }
    }
    .padding(20)
    .frame(minWidth: 600, idealWidth: 640, maxWidth: .infinity, minHeight: 380, idealHeight: 400, maxHeight: .infinity)
  }

  private func amountField(_ title: String, _ value: Binding<Double?>) -> some View {
    TextField(title, value: value, format: Fmt.moneyInput, prompt: Text("0"))
      .labelsHidden()
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
      .frame(width: 180)
  }

  private func save() {
    let snapshot = Snapshot(date: date, rates: rates, rub: rub ?? 0, usd: usd ?? 0, eur: eur ?? 0)
    snapshot.setRates(rates, requestedFor: ratesRequestedFor)
    context.insert(snapshot)
    try? context.save()
    dismiss()
  }
}

#Preview {
  ArchiveEntrySheet()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
