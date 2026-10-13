import SwiftUI

/// The provider chosen in Settings, which every rates editor fetches from.
@propertyWrapper
struct SelectedRateProvider: DynamicProperty {
  @AppStorage("ratesProviderID") private var storedID = RateSource.cbrXML.storedID

  /// An available provider in place of a stored choice that is unknown or has been retired.
  var wrappedValue: RateSource {
    get {
      guard let source = RateSource(storedID: storedID), source.isAvailable else { return RateSource.available[0] }
      return source
    }
    nonmutating set { storedID = newValue.storedID }
  }

  var projectedValue: Binding<RateSource> {
    Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
  }
}
