import Foundation

/// User-facing text for a failed rate fetch, shared by every rates editor.
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
