import Foundation

/// https://www.cbr-xml-daily.ru — unofficial JSON mirror of the CBR daily rates.
enum CBRJSONProvider {
  static func fetch(on date: Date) async throws -> Rates {
    // The archive has no file for weekends/holidays: step back up to a week.
    let path = RateFetch.dateFormatter("yyyy/MM/dd")
    var day = date
    for _ in 0...7 {
      let url = URL(string: "https://www.cbr-xml-daily.ru/archive/\(path.string(from: day))/daily_json.js")!
      let (data, status) = try await RateFetch.download(url)
      if status == 200 { return try RateFetch.makeRates(parse(data), date: date, source: .cbrJSON) }
      guard status == 404 else { throw RateFetchError.badStatus(status) }
      day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
    }
    throw RateFetchError.notFound
  }

  /// "Currency code → RUB per unit".
  private static func parse(_ data: Data) throws -> [String: Double] {
    guard let response = try? JSONDecoder().decode(DailyRatesResponse.self, from: data) else {
      throw RateFetchError.malformed
    }
    return response.Valute.compactMapValues { $0.Nominal > 0 ? $0.Value / $0.Nominal : nil }
  }
}

private struct DailyRatesResponse: Decodable {
  struct Valute: Decodable {
    let Nominal: Double
    let Value: Double
  }
  let Valute: [String: Valute]
}
