import SwiftUI

/// The source exchange rates are fetched from.
struct RatesSettingsView: View {
  @AppStorage(RateSource.selectionKey) private var selectedProvider = RateSource.cbrXML

  /// Selected provider; falls back to an available one if the stored choice was retired.
  private var provider: Binding<RateSource> {
    Binding(get: { selectedProvider.availableOrFirst }, set: { selectedProvider = $0 })
  }

  var body: some View {
    Form {
      Picker(selection: provider) {
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
