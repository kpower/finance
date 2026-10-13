import SwiftUI

/// The source exchange rates are fetched from.
struct RatesSettingsView: View {
  @SelectedRateProvider private var provider: RateSource

  var body: some View {
    Form {
      Picker(selection: $provider) {
        ForEach(RateSource.available) { Text($0.title).tag($0) }
      } label: {
        Text(.settingsRatesSourcePicker)
      }
    }
    .formStyle(.grouped)
  }
}

#Preview {
  RatesSettingsView()
}
