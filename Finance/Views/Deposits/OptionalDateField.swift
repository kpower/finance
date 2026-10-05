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
          "",
          selection: Binding(get: { current }, set: { date = $0 }),
          displayedComponents: .date
        )
        .datePickerStyle(.field)
        .labelsHidden()
        .environment(\.locale, Fmt.ruLocale)
        Button("Очистить", systemImage: "xmark.circle.fill") { date = nil }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .foregroundStyle(.tertiary)
          .help("Очистить дату")
      }
    } else {
      HStack(spacing: 4) {
        Text("—").foregroundStyle(.tertiary)
        Button("Указать дату", systemImage: "plus.circle") { date = defaultDate }
          .labelStyle(.iconOnly)
          .buttonStyle(.borderless)
          .foregroundStyle(.secondary)
          .help("Указать дату")
      }
    }
  }
}

#Preview {
  @Previewable @State var date: Date?
  OptionalDateField(date: $date)
    .padding()
}
