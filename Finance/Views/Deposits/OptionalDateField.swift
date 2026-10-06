import SwiftUI

/// Date editor for an optional date: a "+" button when empty, a compact picker with a clear button when set.
struct OptionalDateField: View {
  @Binding var date: Date?
  /// Value assigned when the user taps "+".
  var defaultDate: Date = .now

  var body: some View {
    if let current = date {
      HStack(spacing: 4) {
        DatePicker(
          selection: Binding(get: { current }, set: { date = $0 }),
          displayedComponents: .date
        ) { EmptyView() }
        .datePickerStyle(.field)
        .labelsHidden()
        Button { date = nil } label: {
          Label { Text(.optionalDateFieldClearButton) } icon: { Image(systemName: "xmark.circle.fill") }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.tertiary)
        .help(Text(.optionalDateFieldClearHelp))
      }
    } else {
      HStack(spacing: 4) {
        Text(verbatim: "—").foregroundStyle(.tertiary)
        Button { date = defaultDate } label: {
          Label { Text(.optionalDateFieldSetButton) } icon: { Image(systemName: "plus.circle") }
        }
        .labelStyle(.iconOnly)
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
        .help(Text(.optionalDateFieldSetHelp))
      }
    }
  }
}

#Preview {
  @Previewable @State var date: Date?
  OptionalDateField(date: $date)
    .padding()
}
