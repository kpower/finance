import SwiftUI

extension EnvironmentValues {
  /// Where a pushed screen reports that it holds edits that are not saved yet; `MainView` reads it
  /// before switching the section. Goes nowhere outside the main window, e.g. in previews.
  @Entry var unsavedEdits: Binding<Bool> = .constant(false)
}

extension View {
  func reportsUnsavedEdits(_ hasUnsavedEdits: Bool) -> some View {
    modifier(UnsavedEditsReporter(hasUnsavedEdits: hasUnsavedEdits))
  }
}

private struct UnsavedEditsReporter: ViewModifier {
  let hasUnsavedEdits: Bool
  @Environment(\.unsavedEdits) private var unsavedEdits

  func body(content: Content) -> some View {
    content.onChange(of: hasUnsavedEdits, initial: true) { unsavedEdits.wrappedValue = hasUnsavedEdits }
  }
}
