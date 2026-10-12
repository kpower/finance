import Foundation
import SwiftData
import SwiftUI

struct DepositsView: View {
  /// Rates typed or fetched here and not saved to history yet. Owned by the window, so they survive
  /// switching sections; they are stored only as part of a snapshot.
  @Binding var draftRates: Rates?

  @Environment(\.modelContext) private var modelContext
  @Query(sort: \Deposit.createdAt) private var deposits: [Deposit]
  @Query(DepositsView.latestSnapshot) private var latestSnapshots: [Snapshot]

  @State private var selection = Set<Deposit.ID>()
  @State private var alert: DepositsAlert?
  @State private var confirmReplace = false

  private static var latestSnapshot: FetchDescriptor<Snapshot> {
    var descriptor = FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date, order: .reverse)])
    descriptor.fetchLimit = 1
    return descriptor
  }

  /// Rates set here; until then, the ones the latest history entry was saved with; nil when there are none.
  private var rates: Rates? { draftRates ?? latestSnapshots.first?.rates }

  var body: some View {
    let rates = rates
    Group {
      if deposits.isEmpty {
        ContentUnavailableView {
          Label { Text(.depositsEmptyTitle) } icon: { Image(systemName: "banknote") }
        } description: {
          Text(.depositsEmptyDescription)
        } actions: {
          Button(action: addDeposit) { Text(.depositsEmptyAddButton) }
            .buttonStyle(.borderedProminent)
        }
      } else {
        VStack(spacing: 0) {
          table(rates: rates)
          Divider()
          DepositsSummaryBar(deposits: deposits, rates: rates) { draftRates = $0 }
        }
      }
    }
    .navigationTitle(Text(.depositsNavigationTitle))
    .toolbar {
      ToolbarItemGroup {
        Button(action: addDeposit) {
          Label { Text(.depositsToolbarAddButton) } icon: { Image(systemName: "plus") }
        }
        Button(action: deleteSelected) {
          Label { Text(.depositsToolbarDeleteButton) } icon: { Image(systemName: "trash") }
        }
        .disabled(selection.isEmpty)
        Button(action: requestSnapshot) {
          Label { Text(.depositsToolbarSaveToHistoryButton) } icon: { Image(systemName: "clock.arrow.circlepath") }
        }
        .disabled(deposits.isEmpty)
      }
    }
    .alert(item: $alert) { item in
      Alert(
        title: Text(item.title),
        message: Text(item.message),
        dismissButton: .default(Text(.depositsAlertOkButton))
      )
    }
    .confirmationDialog(
      Text(.depositsReplaceDialogTitle),
      isPresented: $confirmReplace,
      titleVisibility: .visible
    ) {
      Button(role: .destructive, action: captureSnapshot) { Text(.depositsReplaceDialogReplaceButton) }
      Button(role: .cancel) {} label: { Text(.depositsReplaceDialogCancelButton) }
    } message: {
      Text(.depositsReplaceDialogMessage)
    }
  }

  // MARK: Table

  private func table(rates: Rates?) -> some View {
    let banks = Set(deposits.map { $0.bank.trimmingCharacters(in: .whitespaces) })
      .filter { !$0.isEmpty }
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    return Table(deposits, selection: $selection) {
      TableColumn(Text(.depositsTableNameColumn)) { deposit in
        TextCell(text: Bindable(deposit).name, prompt: Text(.depositsTableNamePrompt))
      }
      .width(min: 120, ideal: 180)

      TableColumn(Text(.depositsTableBankColumn)) { deposit in
        BankCell(deposit: deposit, banks: banks)
      }
      .width(min: 100, ideal: 140)

      TableColumn(Text(verbatim: "₽")) { deposit in
        AmountCell(value: Bindable(deposit).amountRUB)
      }
      .width(min: 90, ideal: 120)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "$")) { deposit in
        AmountCell(value: Bindable(deposit).amountUSD)
      }
      .width(min: 80, ideal: 100)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "€")) { deposit in
        AmountCell(value: Bindable(deposit).amountEUR)
      }
      .width(min: 80, ideal: 100)
      .alignment(.trailing)

      TableColumn(Text(.depositsTableTotalRubColumn)) { deposit in
        TotalCell(deposit: deposit, rates: rates)
      }
      .width(min: 100, ideal: 130)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "%")) { deposit in
        AmountCell(value: Bindable(deposit).interestRate)
      }
      .width(min: 50, ideal: 60)
      .alignment(.trailing)

      TableColumn(Text(.depositsTableTermColumn)) { deposit in
        TermCell(deposit: deposit)
      }
      .width(min: 60, ideal: 80)
      .alignment(.trailing)

      TableColumn(Text(.depositsTableOpenDateColumn)) { deposit in
        OptionalDateField(
          date: Binding(
            get: { deposit.openDate },
            set: { deposit.updateTerm(openDate: $0, termMonths: deposit.termMonths) }
          )
        )
      }
      .width(min: 130, ideal: 150)

      TableColumn(Text(.depositsTableCloseDateColumn)) { deposit in
        CloseDateCell(deposit: deposit)
      }
      .width(min: 150, ideal: 170)
    }
    .onDeleteCommand(perform: deleteSelected)
  }

  // MARK: Actions

  private func addDeposit() {
    // A blank row for the user to fill in.
    let deposit = Deposit(
      name: "", bank: "", amountRUB: nil, amountUSD: nil, amountEUR: nil,
      interestRate: nil, termMonths: nil, openDate: nil, closeDate: nil, createdAt: .now
    )
    modelContext.insert(deposit)
    // Save so the identifier becomes permanent before it is used for selection.
    try? modelContext.save()
    selection = [deposit.id]
  }

  private func deleteSelected() {
    for deposit in deposits where selection.contains(deposit.id) {
      modelContext.delete(deposit)
    }
    selection = []
  }

  private func requestSnapshot() {
    guard rates != nil else {
      alert = DepositsAlert(
        title: String(localized: .depositsNoRatesAlertTitle),
        message: String(localized: .depositsNoRatesAlertMessage)
      )
      return
    }
    if SnapshotService.isDayTaken(.now, excluding: nil, in: modelContext) {
      confirmReplace = true
    } else {
      captureSnapshot()
    }
  }

  private func captureSnapshot() {
    guard let rates else { return }
    do {
      try SnapshotService.capture(deposits: deposits, rates: rates, on: .now, in: modelContext)
      alert = DepositsAlert(
        title: String(localized: .depositsSavedAlertTitle),
        message: String(localized: .depositsSavedAlertMessage(Fmt.date(.now)))
      )
    } catch {
      alert = DepositsAlert(
        title: String(localized: .depositsSaveFailedAlertTitle),
        message: String(localized: .depositsSaveFailedAlertMessage)
      )
    }
  }
}

private struct DepositsAlert: Identifiable {
  let id = UUID()
  let title: String
  let message: String
}

// MARK: - Cells

private struct TextCell: View {
  @Binding var text: String
  var prompt: Text

  var body: some View {
    TextField(text: $text, prompt: prompt) { prompt }
      .textFieldStyle(.plain)
  }
}

private struct BankCell: View {
  @Bindable var deposit: Deposit
  let banks: [String]

  private var suggestions: [String] {
    let text = deposit.bank.trimmingCharacters(in: .whitespaces)
    return banks.filter { $0.range(of: text, options: [.anchored, .caseInsensitive]) != nil && $0 != text }
  }

  var body: some View {
    TextField(text: $deposit.bank, prompt: Text(.depositsTableBankPrompt)) { Text(.depositsTableBankPrompt) }
      .textFieldStyle(.plain)
      .textInputSuggestions {
        ForEach(suggestions, id: \.self) { bank in
          Text(bank).textInputCompletion(bank)
        }
      }
  }
}

private struct AmountCell: View {
  @Binding var value: Double?

  var body: some View {
    TextField(value: $value, format: Fmt.moneyInput, prompt: Text(verbatim: "—")) { EmptyView() }
      .textFieldStyle(.plain)
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
  }
}

private struct TermCell: View {
  @Bindable var deposit: Deposit

  var body: some View {
    TextField(
      value: Binding(
        get: { deposit.termMonths },
        set: { deposit.updateTerm(openDate: deposit.openDate, termMonths: $0) }
      ),
      format: .number.grouping(.never),
      prompt: Text(verbatim: "—")
    ) { EmptyView() }
    .textFieldStyle(.plain)
    .multilineTextAlignment(.trailing)
    .monospacedDigit()
  }
}

/// Close date: calculated from open date and term, can be overridden by hand.
private struct CloseDateCell: View {
  let deposit: Deposit

  var body: some View {
    HStack(spacing: 4) {
      OptionalDateField(
        date: Bindable(deposit).closeDate,
        defaultDate: deposit.expectedCloseDate ?? .now
      )
      if deposit.isCloseDateManual, let expected = deposit.expectedCloseDate {
        Button(action: deposit.recalculateCloseDate) {
          Label { Text(.depositsTableRecalculateCloseDateButton) } icon: { Image(systemName: "arrow.uturn.backward.circle") }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.orange)
        .help(Text(.depositsTableRecalculateCloseDateHelp(Fmt.date(expected))))
      }
    }
  }
}

private struct TotalCell: View {
  let deposit: Deposit
  /// Nil when not entered yet.
  let rates: Rates?

  /// Without rates the total is known only when there is nothing to convert.
  private var total: Double? {
    if let rates { return deposit.totalRUB(at: rates) }
    return deposit.amountUSD == nil && deposit.amountEUR == nil ? deposit.amountRUB ?? 0 : nil
  }

  var body: some View {
    Group {
      if deposit.isEmpty {
        Text(verbatim: "—").foregroundStyle(.tertiary)
      } else if let total {
        Text(Fmt.money(total))
      } else {
        Text(.depositsTableNoRateLabel).foregroundStyle(.secondary)
      }
    }
    .monospacedDigit()
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}

// MARK: - Preview

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  let context = container.mainContext
  let now = Date.now
  context.insert(Deposit(
    name: "Накопительный", bank: "Сбер", amountRUB: 1_500_000, amountUSD: nil, amountEUR: nil,
    interestRate: 16.5, termMonths: nil, openDate: nil, closeDate: nil, createdAt: now
  ))
  context.insert(Deposit(
    name: "Валютный", bank: "ВТБ", amountRUB: nil, amountUSD: 10_000, amountEUR: 2_500,
    interestRate: 3, termMonths: 12, openDate: now, closeDate: nil, createdAt: now.addingTimeInterval(1)
  ))
  context.insert(Deposit(
    name: "Смешанный", bank: "Т-Банк", amountRUB: 300_000, amountUSD: 1_000, amountEUR: nil,
    interestRate: 18, termMonths: 6, openDate: now,
    closeDate: Deposit.expectedCloseDate(openDate: now, termMonths: 6),
    createdAt: now.addingTimeInterval(2)
  ))
  let rates = Rates(usd: 92.5432, eur: 100.1234, date: now, source: .cbrXML)
  return NavigationStack { DepositsView(draftRates: .constant(rates)) }
    .modelContainer(container)
    .frame(width: 1200, height: 500)
}
