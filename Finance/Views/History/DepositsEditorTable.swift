import Foundation
import SwiftUI

/// Editable deposits of a detailed history entry.
/// A cell is highlighted when its value differs from the saved one; every cell of an added deposit is.
struct DepositsEditorTable: View {
  @Binding var items: [Deposit]
  /// Saved deposits, matched to `items` by id.
  let saved: [Deposit]
  let rates: Rates?
  @Binding var selection: Set<Deposit.ID>
  let onAdd: () -> Void
  let onDeleteSelected: () -> Void

  var body: some View {
    if items.isEmpty {
      ContentUnavailableView {
        Label { Text(.historyDetailEmptyTitle) } icon: { Image(systemName: "banknote") }
      } description: {
        Text(.historyDetailEmptyDescription)
      } actions: {
        Button(action: onAdd) { Text(.historyDetailEmptyAddButton) }
          .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      table
    }
  }

  // MARK: Table

  private var table: some View {
    let savedByID = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    let banks = Set(items.map { $0.bank.trimmingCharacters(in: .whitespaces) })
      .filter { !$0.isEmpty }
      .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

    func isChanged<Value: Equatable>(_ item: Deposit, _ field: KeyPath<Deposit, Value>) -> Bool {
      guard let saved = savedByID[item.id] else { return true }
      return item[keyPath: field] != saved[keyPath: field]
    }

    return Table(items, selection: $selection) {
      TableColumn(Text(.historyDetailTableNameColumn)) { item in
        TextCell(text: binding(to: item).name, prompt: Text(.historyDetailTableNamePrompt))
          .changeHighlight(isChanged(item, \.name))
      }
      .width(min: 120, ideal: 180)

      TableColumn(Text(.historyDetailTableBankColumn)) { item in
        BankCell(bank: binding(to: item).bank, banks: banks)
          .changeHighlight(isChanged(item, \.bank))
      }
      .width(min: 100, ideal: 140)

      TableColumn(Text(verbatim: "₽")) { item in
        AmountCell(value: binding(to: item).amountRUB)
          .changeHighlight(isChanged(item, \.amountRUB))
      }
      .width(min: 90, ideal: 120)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "$")) { item in
        AmountCell(value: binding(to: item).amountUSD)
          .changeHighlight(isChanged(item, \.amountUSD))
      }
      .width(min: 80, ideal: 100)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "€")) { item in
        AmountCell(value: binding(to: item).amountEUR)
          .changeHighlight(isChanged(item, \.amountEUR))
      }
      .width(min: 80, ideal: 100)
      .alignment(.trailing)

      TableColumn(Text(.historyDetailTableTotalRubColumn)) { item in
        TotalCell(deposit: item, rates: rates)
      }
      .width(min: 100, ideal: 130)
      .alignment(.trailing)

      TableColumn(Text(verbatim: "%")) { item in
        AmountCell(value: binding(to: item).interestRate)
          .changeHighlight(isChanged(item, \.interestRate))
      }
      .width(min: 50, ideal: 60)
      .alignment(.trailing)

      TableColumn(Text(.historyDetailTableTermColumn)) { item in
        TermCell(deposit: binding(to: item))
          .changeHighlight(isChanged(item, \.termMonths))
      }
      .width(min: 60, ideal: 80)
      .alignment(.trailing)

      TableColumn(Text(.historyDetailTableOpenDateColumn)) { item in
        let deposit = binding(to: item)
        OptionalDateField(
          date: Binding(
            get: { deposit.wrappedValue.openDate },
            set: { deposit.wrappedValue.updateTerm(openDate: $0, termMonths: deposit.wrappedValue.termMonths) }
          )
        )
        .changeHighlight(isChanged(item, \.openDate))
      }
      .width(min: 130, ideal: 150)

      TableColumn(Text(.historyDetailTableCloseDateColumn)) { item in
        CloseDateCell(deposit: binding(to: item))
          .changeHighlight(isChanged(item, \.closeDate))
      }
      .width(min: 150, ideal: 170)
    }
    .onDeleteCommand(perform: onDeleteSelected)
  }

  /// Binding to the deposit with `item`'s id. A cell can outlive its deposit for a moment after it is
  /// removed, so reads then fall back to `item`, the value the cell was built with.
  private func binding(to item: Deposit) -> Binding<Deposit> {
    Binding(
      get: { items.first { $0.id == item.id } ?? item },
      set: { newValue in
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index] = newValue
      }
    )
  }
}

// MARK: - Cells

private struct TextCell: View {
  @Binding var text: String
  let prompt: Text

  var body: some View {
    TextField(text: $text, prompt: prompt) { prompt }
      .textFieldStyle(.plain)
  }
}

private struct BankCell: View {
  @Binding var bank: String
  /// Banks of all deposits in the entry, offered as completions.
  let banks: [String]

  private var suggestions: [String] {
    let text = bank.trimmingCharacters(in: .whitespaces)
    return banks.filter { $0.range(of: text, options: [.anchored, .caseInsensitive]) != nil && $0 != text }
  }

  var body: some View {
    TextField(text: $bank, prompt: Text(.historyDetailTableBankPrompt)) { Text(.historyDetailTableBankPrompt) }
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
  @Binding var deposit: Deposit

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
  @Binding var deposit: Deposit

  var body: some View {
    HStack(spacing: 4) {
      OptionalDateField(date: $deposit.closeDate, defaultDate: deposit.expectedCloseDate ?? .now)
      if deposit.isCloseDateManual, let expected = deposit.expectedCloseDate {
        Button { deposit.recalculateCloseDate() } label: {
          Label { Text(.historyDetailTableRecalculateCloseDateButton) } icon: { Image(systemName: "arrow.uturn.backward.circle") }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.orange)
        .help(Text(.historyDetailTableRecalculateCloseDateHelp(Fmt.date(expected))))
      }
    }
  }
}

private struct TotalCell: View {
  let deposit: Deposit
  let rates: Rates?

  /// Without rates the total is known only when there is nothing to convert.
  private var total: Double? {
    if let rates { return deposit.totalRUB(at: rates) }
    return deposit.amountUSD == nil && deposit.amountEUR == nil ? deposit.amountRUB ?? 0 : nil
  }

  var body: some View {
    Group {
      if deposit.hasNoAmounts {
        Text(verbatim: "—").foregroundStyle(.tertiary)
      } else if let total {
        Text(Fmt.money(total))
      } else {
        Text(.historyDetailTableNoRateLabel).foregroundStyle(.secondary)
      }
    }
    .monospacedDigit()
    .frame(maxWidth: .infinity, alignment: .trailing)
  }
}
