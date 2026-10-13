import SwiftUI

extension View {
  /// Tints a field whose value differs from the saved one. The tint reaches a little past the field,
  /// so it also shows around controls that paint their own background.
  func changeHighlight(_ isChanged: Bool) -> some View {
    background {
      RoundedRectangle(cornerRadius: 5).fill(.yellow.opacity(isChanged ? 0.35 : 0)).padding(-3)
    }
  }
}
