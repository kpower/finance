import Foundation

/// User-facing text for a failed rate fetch, shared by the Rates section and history rate editing.
enum RateFetchFailureText {
  static func text(for error: any Error) -> LocalizedStringResource {
    switch error {
    case is URLError: .rateFetchFailureNetworkMessage
    case RateFetchError.notFound: .rateFetchFailureNotFoundMessage
    case RateFetchError.providerUnavailable: .rateFetchFailureProviderUnavailableMessage
    default: .rateFetchFailureGenericMessage
    }
  }
}
