import Foundation

/// https://www.cbr-xml-daily.ru — unofficial JSON mirror of the CBR daily rates.
struct CBRJSONProvider: RateProvider {
  let id = "cbr-json"
  let title = "cbr-xml-daily.ru (JSON)"

  private struct Response: Decodable {
    struct Valute: Decodable {
      let Nominal: Double
      let Value: Double
    }
    let Date: String
    let Valute: [String: Valute]
  }

  func fetch(on date: Date?) async throws -> Rates {
    guard let date else {
      let (data, status) = try await Self.download(URL(string: "https://www.cbr-xml-daily.ru/daily_json.js")!)
      guard status == 200 else { throw RateFetchError.badStatus(status) }
      return try Self.parse(data)
    }
    // The archive has no file for weekends/holidays: step back up to a week.
    let path = Self.dateFormatter("yyyy/MM/dd")
    var day = date
    for _ in 0...7 {
      let url = URL(string: "https://www.cbr-xml-daily.ru/archive/\(path.string(from: day))/daily_json.js")!
      let (data, status) = try await Self.download(url)
      if status == 200 { return try Self.parse(data) }
      guard status == 404 else { throw RateFetchError.badStatus(status) }
      day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
    }
    throw RateFetchError.notFound
  }

  static func parse(_ data: Data) throws -> Rates {
    guard let response = try? JSONDecoder().decode(Response.self, from: data) else {
      throw RateFetchError.malformed
    }
    // "2026-10-06T11:30:00+03:00" — the calendar day is what matters.
    let date = dateFormatter("yyyy-MM-dd").date(from: String(response.Date.prefix(10)))
    let values = response.Valute.compactMapValues { $0.Nominal > 0 ? $0.Value / $0.Nominal : nil }
    return try makeRates(values, date: date)
  }
}
