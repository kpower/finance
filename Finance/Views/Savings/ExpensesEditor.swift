import SwiftUI

/// Editable regular expenses of a savings entry: blocks, each a single amount or split into named parts.
/// A field is highlighted when its value differs from the saved one; every field of an added block is.
struct ExpensesEditor: View {
  @Binding var blocks: [ExpenseBlock]
  /// Saved blocks, matched to `blocks` by id.
  let saved: [ExpenseBlock]
  let onAdd: () -> Void

  var body: some View {
    if blocks.isEmpty {
      ContentUnavailableView {
        Label { Text(.savingsDetailExpensesEmptyTitle) } icon: { Image(systemName: "cart") }
      } description: {
        Text(.savingsDetailExpensesEmptyDescription)
      } actions: {
        Button(action: onAdd) { Text(.savingsDetailExpensesEmptyAddButton) }
          .buttonStyle(.borderedProminent)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    } else {
      list
    }
  }

  private var list: some View {
    let savedByID = Dictionary(saved.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
    return ScrollView {
      VStack(alignment: .leading, spacing: 14) {
        ForEach(blocks) { block in
          BlockEditor(block: binding(to: block), saved: savedByID[block.id]) {
            blocks.removeAll { $0.id == block.id }
          }
        }
      }
      .frame(maxWidth: 620)
      .padding(16)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }

  /// Binding to the block with `block`'s id. A field can outlive its block for a moment after it is
  /// removed, so reads then fall back to `block`, the value the field was built with.
  private func binding(to block: ExpenseBlock) -> Binding<ExpenseBlock> {
    Binding(
      get: { blocks.first { $0.id == block.id } ?? block },
      set: { newValue in
        guard let index = blocks.firstIndex(where: { $0.id == block.id }) else { return }
        blocks[index] = newValue
      }
    )
  }
}

// MARK: - Rows

private enum Layout {
  static let amountWidth: CGFloat = 130
  static let buttonWidth: CGFloat = 20
  static let spacing: CGFloat = 8
}

private struct BlockEditor: View {
  @Binding var block: ExpenseBlock
  /// Nil for a block added since the last save.
  let saved: ExpenseBlock?
  let onRemove: () -> Void

  var body: some View {
    VStack(spacing: 6) {
      HStack(spacing: Layout.spacing) {
        TextField(text: $block.name, prompt: Text(.savingsDetailExpensesNamePrompt)) {
          Text(.savingsDetailExpensesNamePrompt)
        }
        .fontWeight(.medium)
        .changeHighlight(block.name != saved?.name)
        amount
        IconButton(title: .savingsDetailExpensesAddPartButton, systemImage: "plus.circle") { block.addPart() }
        IconButton(title: .savingsDetailExpensesRemoveButton, systemImage: "trash", action: onRemove)
      }
      ForEach(block.parts) { part in
        PartEditor(part: binding(to: part), saved: saved?.parts.first { $0.id == part.id }) {
          block.removePart(part)
        }
      }
    }
  }

  /// The single amount to type in, or the sum of the parts.
  @ViewBuilder private var amount: some View {
    switch block.content {
    case let .single(amount):
      AmountField(value: Binding(get: { amount }, set: { block.content = .single(amount: $0) }))
        .changeHighlight(block.content != saved?.content)
    case .split:
      Text(Fmt.money(block.total))
        .monospacedDigit()
        .foregroundStyle(.secondary)
        // Lines the digits up with those inside the fields.
        .padding(.trailing, 6)
        .frame(width: Layout.amountWidth, alignment: .trailing)
    }
  }

  /// Reads fall back to `part` for the moment a field outlives its removed part.
  private func binding(to part: ExpensePart) -> Binding<ExpensePart> {
    Binding(
      get: { block.parts.first { $0.id == part.id } ?? part },
      set: { block.replacePart($0) }
    )
  }
}

private struct PartEditor: View {
  @Binding var part: ExpensePart
  /// Nil for a part added since the last save.
  let saved: ExpensePart?
  let onRemove: () -> Void

  var body: some View {
    HStack(spacing: Layout.spacing) {
      TextField(text: $part.name, prompt: Text(.savingsDetailExpensesPartPrompt)) {
        Text(.savingsDetailExpensesPartPrompt)
      }
      .changeHighlight(part.name != saved?.name)
      AmountField(value: $part.amount)
        .changeHighlight(part.amount != saved?.amount)
      IconButton(title: .savingsDetailExpensesRemovePartButton, systemImage: "minus.circle", action: onRemove)
      // Keeps the amount under the block's one: a block row ends with two buttons.
      Color.clear.frame(width: Layout.buttonWidth, height: 1)
    }
    .padding(.leading, 24)
  }
}

private struct AmountField: View {
  @Binding var value: Double

  var body: some View {
    TextField(value: $value, format: Fmt.moneyInput) { EmptyView() }
      .multilineTextAlignment(.trailing)
      .monospacedDigit()
      .frame(width: Layout.amountWidth)
  }
}

private struct IconButton: View {
  let title: LocalizedStringResource
  let systemImage: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Label { Text(title) } icon: { Image(systemName: systemImage) }
    }
    .labelStyle(.iconOnly)
    .buttonStyle(.borderless)
    .foregroundStyle(.secondary)
    .frame(width: Layout.buttonWidth)
    .help(Text(title))
  }
}

#Preview {
  @Previewable @State var blocks = PreviewData.expenses
  ExpensesEditor(blocks: $blocks, saved: PreviewData.expenses) {}
    .frame(width: 700, height: 400)
}
