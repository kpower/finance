import SwiftData
import SwiftUI

struct SettingsView: View {
  @AppStorage(SettingsTab.selectionKey) private var tab = SettingsTab.rates

  var body: some View {
    TabView(selection: $tab) {
      Tab(value: SettingsTab.rates) {
        RatesSettingsView()
      } label: {
        Label { Text(.settingsTabRates) } icon: { Image(systemName: "dollarsign.arrow.circlepath") }
      }
      Tab(value: SettingsTab.inflation) {
        InflationSettingsView()
      } label: {
        Label { Text(.settingsTabInflation) } icon: { Image(systemName: "chart.line.uptrend.xyaxis") }
      }
    }
    .frame(width: 460)
  }
}

#Preview {
  SettingsView()
    .modelContainer(for: FinanceSchema.models, inMemory: true)
}
