import Foundation

/// Source of USD/EUR rates (RUB per unit). Fetching is always user-initiated.
protocol RateProvider: Sendable {
  var id: String { get }
  var title: String { get }
  /// Rates for the given date, or the latest published ones when `date` is nil.
  func fetch(on date: Date?) async throws -> Rates
}

enum RateProviders {
  static let all: [any RateProvider] = [CBRXMLProvider(), CBRJSONProvider()]
}

// MARK: - Shared helpers

extension RateProvider {
  static func dateFormatter(_ format: String) -> DateFormatter {
    let f = DateFormatter()
    f.locale = Locale(identifier: "en_US_POSIX")
    f.dateFormat = format
    return f
  }

  /// Response body and HTTP status; transport failures become `RateFetchError.network`.
  static func download(_ url: URL) async throws -> (Data, Int) {
    var request = URLRequest(url: url, timeoutInterval: 20)
    request.setValue("Finance/1.0", forHTTPHeaderField: "User-Agent")
    do {
      let (data, response) = try await URLSession.shared.data(for: request)
      guard let http = response as? HTTPURLResponse else { throw RateFetchError.malformed }
      return (data, http.statusCode)
    } catch let error as RateFetchError {
      throw error
    } catch {
      throw RateFetchError.network(error.localizedDescription)
    }
  }

  /// Picks USD and EUR out of a "currency code → RUB per unit" map.
  static func makeRates(_ values: [String: Double], date: Date?) throws -> Rates {
    guard let usd = values["USD"] else { throw RateFetchError.missingCurrency("USD") }
    guard let eur = values["EUR"] else { throw RateFetchError.missingCurrency("EUR") }
    guard usd > 0, eur > 0 else { throw RateFetchError.malformed }
    return Rates(usd: usd, eur: eur, date: date)
  }
}
