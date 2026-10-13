import SwiftUI

/// Why an entry is not calculated, with a button that opens the place to enter the missing data.
struct SavingsGapNotice: View {
  let gap: SavingsGap
  let openYears: () -> Void

  @Environment(\.openSettings) private var openSettings
  @AppStorage(SettingsTab.selectionKey) private var settingsTab = SettingsTab.rates

  var body: some View {
    HStack(spacing: 8) {
      Label { Text(gap.message) } icon: { Image(systemName: "exclamationmark.triangle.fill") }
        .foregroundStyle(.orange)
      Button(action: open) { Text(.savingsGapOpenButton) }
        .help(Text(destinationHelp))
    }
  }

  private var destinationHelp: LocalizedStringResource {
    switch gap {
    case .parameters: .savingsGapParametersHelp
    case .inflation: .savingsGapInflationHelp
    }
  }

  private func open() {
    switch gap {
    case .parameters:
      openYears()
    case .inflation:
      settingsTab = .inflation
      openSettings()
    }
  }
}

extension SavingsGap {
  var message: LocalizedStringResource {
    switch self {
    case let .parameters(year): .savingsGapParametersMessage(String(year))
    case let .inflation(year): .savingsGapInflationMessage(String(year))
    }
  }
}
