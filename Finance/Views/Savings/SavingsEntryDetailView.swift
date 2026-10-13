import SwiftData
import SwiftUI

/// A savings entry opened for editing: a stored one, or a new one that is stored by its first save.
/// Edits stay in a draft and are highlighted; only Save writes them to the entry, and leaving the screen
/// or closing the window with unsaved edits asks what to do with them.
struct SavingsEntryDetailView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss
  @Query private var entries: [SavingsEntry]
  @Query private var years: [SavingsYear]
  @Query private var inflation: [AnnualInflation]

  /// Shows the year parameters over this screen; the draft stays as it is underneath.
  private let openYears: () -> Void
  /// Entry the draft is saved to; nil while a new entry has not been saved yet.
  @State private var stored: SavingsEntry?
  /// What the draft is compared with: the stored values, or what a new entry started from.
  @State private var saved: SavingsEntryDraft
  @State private var draft: SavingsEntryDraft
  @State private var isConfirmingExit = false
  @State private var isSaveFailureShown = false

  init(entry: SavingsEntry, openYears: @escaping () -> Void) {
    let draft = SavingsEntryDraft(entry)
    self.openYears = openYears
    _stored = State(initialValue: entry)
    _saved = State(initialValue: draft)
    _draft = State(initialValue: draft)
  }

  /// A new entry that starts from the income and expenses of `latest`.
  init(newEntryAfter latest: SavingsEntry?, openYears: @escaping () -> Void) {
    let draft = SavingsEntryDraft.newEntry(after: latest)
    self.openYears = openYears
    _stored = State(initialValue: nil)
    _saved = State(initialValue: draft)
    _draft = State(initialValue: draft)
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      ExpensesEditor(blocks: $draft.expenses, saved: saved.expenses, onAdd: addExpense)
      Divider()
      footer
    }
    .navigationTitle(stored == nil ? Text(.savingsDetailNewTitle) : Text(.savingsDetailTitle(Fmt.date(saved.date))))
    .reportsUnsavedEdits(hasUnsavedChanges)
    // The system back button cannot be asked to wait for a confirmation, so the screen has its own.
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button(action: requestExit) {
          Label { Text(.savingsDetailToolbarBackButton) } icon: { Image(systemName: "chevron.backward") }
        }
      }
      ToolbarItem {
        Button(action: addExpense) {
          Label { Text(.savingsDetailToolbarAddExpenseButton) } icon: { Image(systemName: "plus") }
        }
      }
      ToolbarItem {
        Button { save() } label: { Text(.savingsDetailToolbarSaveButton) }
          .keyboardShortcut("s", modifiers: .command)
          .disabled(!canSave)
      }
    }
    .confirmationDialog(exitDialogTitle, isPresented: $isConfirmingExit, titleVisibility: .visible) {
      exitDialogActions { dismiss() }
      Button(role: .cancel) {} label: { Text(.savingsDetailExitDialogCancelButton) }
    } message: {
      exitDialogMessage
    }
    // Closing the window or quitting the app; the system closes the window after either action.
    .dismissalConfirmationDialog(exitDialogTitle, shouldPresent: hasUnsavedChanges) {
      exitDialogActions {}
    } message: {
      exitDialogMessage
    }
    .alert(Text(.savingsDetailSaveFailedAlertTitle), isPresented: $isSaveFailureShown) {
      Button {} label: { Text(.savingsDetailSaveFailedAlertOkButton) }
    } message: {
      Text(.savingsDetailSaveFailedAlertMessage)
    }
  }

  // MARK: Draft state

  private var hasUnsavedChanges: Bool { draft != saved }

  private var otherEntries: [SavingsEntry] {
    entries.filter { $0.persistentModelID != stored?.persistentModelID }
  }

  private var validation: SavingsValidation {
    if otherEntries.contains(where: { $0.date == draft.date }) { return .blocked(.dayTaken) }
    guard let grossMonthly = draft.grossMonthly else { return .blocked(.noIncome) }
    return .ready(grossMonthly: grossMonthly)
  }

  /// A new entry can be saved as it started; a stored one only when something changed.
  private var canSave: Bool {
    switch validation {
    case .ready: stored == nil || hasUnsavedChanges
    case .blocked: false
    }
  }

  /// What the draft would give among the other entries; nil until its income is entered.
  private var outcome: SavingsOutcome? {
    guard let grossMonthly = draft.grossMonthly else { return nil }
    let input = SavingsInput(date: draft.date, grossMonthly: grossMonthly, expensesTotal: draft.expenses.total)
    return SavingsPlan(entries: otherEntries.map(\.input) + [input], years: years, inflation: inflation)?
      .outcome(for: input)
  }

  /// Writes the draft to the entry, creating the entry on the first save of a new one.
  @discardableResult
  private func save() -> Bool {
    switch validation {
    case let .ready(grossMonthly): save(grossMonthly: grossMonthly)
    case .blocked: false
    }
  }

  private func save(grossMonthly: Double) -> Bool {
    let comment = draft.comment.trimmingCharacters(in: .whitespacesAndNewlines)
    let entry: SavingsEntry
    if let stored {
      stored.date = draft.date
      stored.grossMonthly = grossMonthly
      stored.expenses = draft.expenses
      stored.comment = comment
      entry = stored
    } else {
      entry = SavingsEntry(
        date: draft.date, grossMonthly: grossMonthly, expenses: draft.expenses, comment: comment)
      context.insert(entry)
    }
    do {
      try context.save()
    } catch {
      context.rollback()
      isSaveFailureShown = true
      return false
    }
    stored = entry
    saved = SavingsEntryDraft(entry)
    draft = saved
    return true
  }

  private func addExpense() {
    // A blank block for the user to fill in.
    draft.expenses.append(ExpenseBlock(name: "", content: .single(amount: 0)))
  }

  // MARK: Exit

  private func requestExit() {
    if hasUnsavedChanges {
      isConfirmingExit = true
    } else {
      dismiss()
    }
  }

  private var exitDialogTitle: Text {
    switch validation {
    case .ready: Text(.savingsDetailExitDialogSaveTitle)
    case .blocked: Text(.savingsDetailExitDialogBlockedTitle)
    }
  }

  private var exitDialogMessage: Text {
    switch validation {
    case .ready: Text(.savingsDetailExitDialogSaveMessage)
    case let .blocked(blocker): Text(.savingsDetailExitDialogBlockedMessage(String(localized: blocker.message)))
    }
  }

  /// Save (only when the draft can be saved) and Don't Save; `leave` runs once the choice is carried out.
  @ViewBuilder
  private func exitDialogActions(leave: @escaping () -> Void) -> some View {
    switch validation {
    case .ready:
      Button {
        if save() { leave() }
      } label: {
        Text(.savingsDetailExitDialogSaveButton)
      }
    case .blocked:
      EmptyView()
    }
    Button(role: .destructive, action: leave) { Text(.savingsDetailExitDialogDiscardButton) }
  }

  // MARK: Header

  /// One row when the window is wide enough, otherwise the comment moves to its own row.
  private var header: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 20) {
        dateAndIncome
        commentField.frame(minWidth: 200)
      }
      VStack(alignment: .leading, spacing: 8) {
        dateAndIncome
        commentField
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  private var dateAndIncome: some View {
    HStack(spacing: 20) {
      DatePicker(selection: dateBinding, displayedComponents: .date) { Text(.savingsDetailDateLabel) }
        .datePickerStyle(.field)
        .fixedSize()
        .changeHighlight(draft.date != saved.date)
      LabeledContent {
        TextField(value: $draft.grossMonthly, format: Fmt.moneyInput, prompt: Text(verbatim: "0")) {
          Text(.savingsDetailGrossLabel)
        }
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 140)
      } label: {
        Text(.savingsDetailGrossLabel)
      }
      .fixedSize()
      .changeHighlight(draft.grossMonthly != saved.grossMonthly)
    }
  }

  private var commentField: some View {
    TextField(text: $draft.comment) { Text(.savingsDetailCommentLabel) }
      .frame(maxWidth: .infinity)
      .changeHighlight(draft.comment != saved.comment)
  }

  private var dateBinding: Binding<Date> {
    Binding(get: { draft.date }, set: { draft.date = Calendar.current.startOfDay(for: $0) })
  }

  // MARK: Footer

  private var footer: some View {
    HStack(alignment: .firstTextBaseline, spacing: 24) {
      status
      Spacer()
      switch outcome {
      case let .figures(figures)?:
        figure(Text(.savingsTableNetColumn), Fmt.money(figures.net))
        expensesTotal
        figure(Text(.savingsTableStartMoneyColumn), Fmt.money(figures.startMoney))
        figure(Text(verbatim: "Δ"), Fmt.money(figures.delta))
        figure(Text(.savingsTableSavedShareColumn), Fmt.money(figures.savedShare))
        VStack(alignment: .trailing, spacing: 2) {
          Text(.savingsTableSaveMonthlyColumn).font(.caption).foregroundStyle(.secondary)
          Text(Fmt.signedMoney(figures.saveMonthly)).font(.title3.weight(.semibold)).monospacedDigit()
        }
      case let .missing(gap)?:
        expensesTotal
        SavingsGapNotice(gap: gap, openYears: openYears)
      case nil:
        expensesTotal
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.bar)
  }

  private var expensesTotal: some View {
    figure(Text(.savingsTableExpensesColumn), Fmt.money(draft.expenses.total))
  }

  /// What stands between the draft and the stored entry: why it cannot be saved, or that it differs.
  @ViewBuilder private var status: some View {
    switch validation {
    case let .blocked(blocker):
      Label { Text(blocker.message) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
        .foregroundStyle(.red)
    case .ready:
      if stored == nil {
        Text(.savingsDetailStatusNew).foregroundStyle(.secondary)
      } else if hasUnsavedChanges {
        Text(.savingsDetailStatusUnsaved)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .changeHighlight(true)
      }
    }
  }

  private func figure(_ title: Text, _ value: String) -> some View {
    VStack(alignment: .trailing, spacing: 2) {
      title.font(.caption).foregroundStyle(.secondary)
      Text(value).monospacedDigit()
    }
  }
}

private enum SavingsValidation {
  case ready(grossMonthly: Double)
  case blocked(SavingsSaveBlocker)
}

private enum SavingsSaveBlocker {
  case dayTaken
  case noIncome

  var message: LocalizedStringResource {
    switch self {
    case .dayTaken: .savingsDetailBlockerDayTaken
    case .noIncome: .savingsDetailBlockerNoIncome
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  let entry = (try? container.mainContext.fetch(FetchDescriptor<SavingsEntry>(sortBy: [SortDescriptor(\.date)])))?.last
  return NavigationStack {
    if let entry { SavingsEntryDetailView(entry: entry) {} }
  }
  .modelContainer(container)
  .frame(width: 1100, height: 400)
}

#Preview("New entry") {
  NavigationStack {
    SavingsEntryDetailView(newEntryAfter: nil) {}
  }
  .modelContainer(for: FinanceSchema.models, inMemory: true)
  .frame(width: 1100, height: 400)
}
