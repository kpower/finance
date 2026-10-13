import SwiftUI

/// App settings: the source rates are fetched from.
struct SettingsView: View {
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
    .frame(width: 420)
  }
}

#Preview {
  SettingsView()
}
