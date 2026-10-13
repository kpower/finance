import SwiftData
import SwiftUI

/// A history entry opened for editing: a stored one, or a new detailed one that is stored by its first save.
/// Edits stay in a draft and are highlighted; only Save writes them to the entry, and leaving the screen
/// or closing the window with unsaved edits asks what to do with them.
struct SnapshotDetailView: View {
  @Environment(\.modelContext) private var context
  @Environment(\.dismiss) private var dismiss

  /// Entry the draft is saved to; nil while a new entry has not been saved yet.
  @State private var stored: Snapshot?
  /// What the draft is compared with: the stored values, or what a new entry started from.
  @State private var saved: SnapshotDraft
  @State private var draft: SnapshotDraft
  @State private var selection = Set<Deposit.ID>()
  @State private var isConfirmingClear = false
  @State private var isConfirmingExit = false
  @State private var isSaveFailureShown = false

  init(snapshot: Snapshot) {
    let draft = SnapshotDraft(SnapshotValues(snapshot))
    _stored = State(initialValue: snapshot)
    _saved = State(initialValue: draft)
    _draft = State(initialValue: draft)
  }

  /// A new detailed entry that starts from `deposits`.
  init(newEntryWith deposits: [Deposit]) {
    let draft = SnapshotDraft.newEntry(deposits: deposits)
    _stored = State(initialValue: nil)
    _saved = State(initialValue: draft)
    _draft = State(initialValue: draft)
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      Divider()
      switch draft.content.kind {
      case .detailed:
        DepositsEditorTable(
          items: deposits, saved: saved.content.deposits, rates: draft.rates,
          selection: $selection, onAdd: addDeposit, onDeleteSelected: deleteSelectedDeposits
        )
      case .summaryOnly:
        summaryNote
      }
      Divider()
      footer
    }
    .navigationTitle(title)
    .reportsUnsavedEdits(hasUnsavedChanges)
    // The system back button cannot be asked to wait for a confirmation, so the screen has its own.
    .navigationBarBackButtonHidden()
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Button(action: requestExit) {
          Label { Text(.historyDetailToolbarBackButton) } icon: { Image(systemName: "chevron.backward") }
        }
      }
      ToolbarItemGroup {
        switch draft.content.kind {
        case .detailed: depositButtons
        case .summaryOnly: EmptyView()
        }
      }
      ToolbarItem {
        Button { save() } label: { Text(.historyDetailToolbarSaveButton) }
          .keyboardShortcut("s", modifiers: .command)
          .disabled(!canSave)
      }
    }
    .confirmationDialog(
      Text(.historyDetailClearDialogTitle),
      isPresented: $isConfirmingClear,
      titleVisibility: .visible
    ) {
      Button(role: .destructive, action: clearDeposits) { Text(.historyDetailClearDialogClearButton) }
      Button(role: .cancel) {} label: { Text(.historyDetailClearDialogCancelButton) }
    } message: {
      Text(.historyDetailClearDialogMessage)
    }
    .confirmationDialog(exitDialogTitle, isPresented: $isConfirmingExit, titleVisibility: .visible) {
      exitDialogActions { dismiss() }
      Button(role: .cancel) {} label: { Text(.historyDetailExitDialogCancelButton) }
    } message: {
      exitDialogMessage
    }
    // Closing the window or quitting the app; the system closes the window after either action.
    .dismissalConfirmationDialog(exitDialogTitle, shouldPresent: hasUnsavedChanges) {
      exitDialogActions {}
    } message: {
      exitDialogMessage
    }
    .alert(Text(.historyDetailSaveFailedAlertTitle), isPresented: $isSaveFailureShown) {
      Button {} label: { Text(.historyDetailSaveFailedAlertOkButton) }
    } message: {
      Text(.historyDetailSaveFailedAlertMessage)
    }
  }

  private var title: Text {
    guard stored != nil else { return Text(.historyDetailNewTitle) }
    switch saved.content.kind {
    case .detailed: return Text(.historyDetailDepositsTitle(Fmt.date(saved.date)))
    case .summaryOnly: return Text(.historyDetailArchiveTitle(Fmt.date(saved.date)))
    }
  }

  // MARK: Draft state

  private var hasUnsavedChanges: Bool { draft != saved }

  private var validation: SnapshotValidation {
    if SnapshotService.isDayTaken(draft.date, excluding: stored, in: context) { return .blocked(.dayTaken) }
    guard let rates = draft.rates else { return .blocked(.noRates) }
    switch draft.content {
    case let .detailed(deposits):
      if deposits.isEmpty { return .blocked(.noDeposits) }
    case .summaryOnly:
      break
    }
    return .ready(
      SnapshotValues(
        date: draft.date, rates: rates, content: draft.content,
        comment: draft.comment.trimmingCharacters(in: .whitespacesAndNewlines)
      )
    )
  }

  /// A new entry can be saved as it started; a stored one only when something changed.
  private var canSave: Bool {
    switch validation {
    case .ready: stored == nil || hasUnsavedChanges
    case .blocked: false
    }
  }

  /// Writes the draft to the entry, creating the entry on the first save of a new one.
  @discardableResult
  private func save() -> Bool {
    switch validation {
    case let .ready(values): save(values)
    case .blocked: false
    }
  }

  private func save(_ values: SnapshotValues) -> Bool {
    let snapshot: Snapshot
    if let stored {
      stored.update(from: values)
      snapshot = stored
    } else {
      snapshot = Snapshot(values)
      context.insert(snapshot)
    }
    do {
      try context.save()
    } catch {
      context.rollback()
      isSaveFailureShown = true
      return false
    }
    stored = snapshot
    // Not read back from the store: the deposits would come with other ids and lose their rows.
    saved = SnapshotDraft(values)
    draft = saved
    return true
  }

  // MARK: Deposits

  @ViewBuilder private var depositButtons: some View {
    Button(action: addDeposit) {
      Label { Text(.historyDetailToolbarAddButton) } icon: { Image(systemName: "plus") }
    }
    Button(action: deleteSelectedDeposits) {
      Label { Text(.historyDetailToolbarDeleteButton) } icon: { Image(systemName: "trash") }
    }
    .disabled(selection.isEmpty)
    Button { isConfirmingClear = true } label: {
      Label { Text(.historyDetailToolbarClearAllButton) } icon: { Image(systemName: "clear") }
    }
    .disabled(draft.content.deposits.isEmpty)
  }

  private var deposits: Binding<[Deposit]> {
    Binding(get: { draft.content.deposits }, set: { newValue in updateDeposits { $0 = newValue } })
  }

  /// Changes the deposits of a detailed draft; an archive one has none to change.
  private func updateDeposits(_ change: (inout [Deposit]) -> Void) {
    switch draft.content {
    case var .detailed(deposits):
      change(&deposits)
      draft.content = .detailed(deposits)
    case .summaryOnly:
      break
    }
  }

  private func addDeposit() {
    // A blank row for the user to fill in.
    let deposit = Deposit(
      name: "", bank: "", amountRUB: nil, amountUSD: nil, amountEUR: nil,
      interestRate: nil, termMonths: nil, openDate: nil, closeDate: nil
    )
    updateDeposits { $0.append(deposit) }
    selection = [deposit.id]
  }

  private func deleteSelectedDeposits() {
    updateDeposits { $0.removeAll { selection.contains($0.id) } }
    selection = []
  }

  private func clearDeposits() {
    updateDeposits { $0 = [] }
    selection = []
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
    case .ready: Text(.historyDetailExitDialogSaveTitle)
    case .blocked: Text(.historyDetailExitDialogBlockedTitle)
    }
  }

  private var exitDialogMessage: Text {
    switch validation {
    case .ready: Text(.historyDetailExitDialogSaveMessage)
    case let .blocked(blocker): Text(.historyDetailExitDialogBlockedMessage(String(localized: blocker.message)))
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
        Text(.historyDetailExitDialogSaveButton)
      }
    case .blocked:
      EmptyView()
    }
    Button(role: .destructive, action: leave) { Text(.historyDetailExitDialogDiscardButton) }
  }

  // MARK: Header

  /// One row when the window is wide enough, otherwise the comment moves to its own row.
  private var header: some View {
    ViewThatFits(in: .horizontal) {
      HStack(spacing: 20) {
        dateAndRates
        commentField.frame(minWidth: 200)
      }
      VStack(alignment: .leading, spacing: 8) {
        dateAndRates
        commentField
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
  }

  private var dateAndRates: some View {
    HStack(spacing: 20) {
      DatePicker(selection: dateBinding, displayedComponents: .date) { Text(.historyDetailDateLabel) }
        .datePickerStyle(.field)
        .fixedSize()
        .changeHighlight(draft.date != saved.date)
      RatesEditor(date: draft.date, rates: draft.rates) { draft.rates = $0 }
        .changeHighlight(draft.rates != saved.rates)
    }
  }

  private var commentField: some View {
    TextField(text: $draft.comment) { Text(.historyDetailCommentLabel) }
      .frame(maxWidth: .infinity)
      .changeHighlight(draft.comment != saved.comment)
  }

  private var dateBinding: Binding<Date> {
    Binding(get: { draft.date }, set: { draft.date = Calendar.current.startOfDay(for: $0) })
  }

  // MARK: Content

  private var summaryNote: some View {
    let savedTotals = saved.content.sums
    return ContentUnavailableView {
      Label { Text(.historyDetailSummaryOnlyTitle) } icon: { Image(systemName: "archivebox") }
    } description: {
      Text(.historyDetailSummaryOnlyDescription)
    } actions: {
      HStack(spacing: 20) {
        sumField("₽", value: totals.rub, isChanged: totals.wrappedValue.rub != savedTotals.rub)
        sumField("$", value: totals.usd, isChanged: totals.wrappedValue.usd != savedTotals.usd)
        sumField("€", value: totals.eur, isChanged: totals.wrappedValue.eur != savedTotals.eur)
      }
    }
    // Fills the space between header and footer. Not `fixedSize`: measured at zero width its text
    // wraps one letter per line, and that height pushed the header and footer out of the window.
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  /// Totals of an archive draft; a detailed one has its deposits instead.
  private var totals: Binding<CurrencyAmounts> {
    Binding(
      get: { draft.content.sums },
      set: { newValue in
        switch draft.content {
        case .detailed: break
        case .summaryOnly: draft.content = .summaryOnly(newValue)
        }
      }
    )
  }

  private func sumField(_ title: String, value: Binding<Double>, isChanged: Bool) -> some View {
    LabeledContent(title) {
      TextField(title, value: value, format: Fmt.moneyInput)
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .frame(width: 140)
    }
    .fixedSize()
    .changeHighlight(isChanged)
  }

  // MARK: Footer

  private var footer: some View {
    let sums = draft.content.sums
    return HStack(alignment: .firstTextBaseline, spacing: 24) {
      status
      Spacer()
      sum("Σ ₽", Fmt.money(sums.rub))
      sum("Σ $", Fmt.money(sums.usd))
      sum("Σ €", Fmt.money(sums.eur))
      VStack(alignment: .trailing, spacing: 2) {
        Text(.historyDetailFooterTotalRubLabel).font(.caption).foregroundStyle(.secondary)
        if let rates = draft.rates {
          Text(Fmt.money(sums.totalRUB(at: rates))).font(.title3.weight(.semibold)).monospacedDigit()
        } else {
          Text(.historyDetailFooterNoRateLabel).font(.title3).foregroundStyle(.secondary)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(.bar)
  }

  /// What stands between the draft and the stored entry: why it cannot be saved, or that it differs.
  @ViewBuilder private var status: some View {
    switch validation {
    case let .blocked(blocker):
      Label { Text(blocker.message) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
        .foregroundStyle(.red)
    case .ready:
      if stored == nil {
        Text(.historyDetailStatusNew).foregroundStyle(.secondary)
      } else if hasUnsavedChanges {
        // Removed deposits have no row left to highlight, so they are counted here.
        let removed = saved.content.deposits.count { deposit in !draft.content.deposits.contains { $0.id == deposit.id } }
        Text(removed == 0 ? LocalizedStringResource.historyDetailStatusUnsaved : .historyDetailStatusUnsavedRemoved(removed))
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .changeHighlight(true)
      }
    }
  }

  private func sum(_ title: String, _ value: String) -> some View {
    VStack(alignment: .trailing, spacing: 2) {
      Text(title).font(.caption).foregroundStyle(.secondary)
      Text(value).monospacedDigit()
    }
  }
}

private enum SnapshotValidation {
  case ready(SnapshotValues)
  case blocked(SnapshotSaveBlocker)
}

private enum SnapshotSaveBlocker {
  case dayTaken
  case noRates
  case noDeposits

  var message: LocalizedStringResource {
    switch self {
    case .dayTaken: .historyDetailBlockerDayTaken
    case .noRates: .historyDetailBlockerNoRates
    case .noDeposits: .historyDetailBlockerNoDeposits
    }
  }
}

#Preview {
  let container = try! ModelContainer(
    for: Schema(FinanceSchema.models),
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
  )
  PreviewData.seed(container.mainContext)
  let snapshot = (try? container.mainContext.fetch(FetchDescriptor<Snapshot>(sortBy: [SortDescriptor(\.date)])))?.last
  return NavigationStack {
    if let snapshot { SnapshotDetailView(snapshot: snapshot) }
  }
  .modelContainer(container)
  .frame(width: 1100, height: 400)
}

#Preview("New entry") {
  NavigationStack {
    SnapshotDetailView(newEntryWith: [])
  }
  .modelContainer(for: FinanceSchema.models, inMemory: true)
  .frame(width: 1100, height: 400)
}
