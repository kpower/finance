import Foundation

/// https://www.cbr.ru/scripts/XML_daily.asp — official Bank of Russia rates, windows-1251 XML, decimal comma.
struct CBRXMLProvider: RateProvider {
  func fetch(on date: Date?) async throws -> Rates {
    var components = URLComponents(string: "https://www.cbr.ru/scripts/XML_daily.asp")!
    if let date {
      components.queryItems = [URLQueryItem(name: "date_req", value: Self.dateFormatter("dd/MM/yyyy").string(from: date))]
    }
    let (data, status) = try await Self.download(components.url!)
    guard status == 200 else { throw RateFetchError.badStatus(status) }
    return try Self.parse(data)
  }

  private static func parse(_ data: Data) throws -> Rates {
    // XMLParser can't be trusted with windows-1251 declarations; transcode to UTF-8 first.
    guard var text = String(data: data, encoding: .windowsCP1251) else { throw RateFetchError.malformed }
    if let range = text.range(of: #"encoding="[^"]*""#, options: .regularExpression) {
      text.replaceSubrange(range, with: #"encoding="UTF-8""#)
    }
    let delegate = Delegate()
    let parser = XMLParser(data: Data(text.utf8))
    unsafe parser.delegate = delegate
    guard parser.parse() else { throw RateFetchError.malformed }
    let date = delegate.dateString.flatMap { dateFormatter("dd.MM.yyyy").date(from: $0) }
    return try makeRates(delegate.values, date: date)
  }

  private final class Delegate: NSObject, XMLParserDelegate {
    var values: [String: Double] = [:]
    var dateString: String?
    private var code = "", nominal = "", value = "", buffer = ""

    func parser(
      _ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
      qualifiedName: String?, attributes: [String: String] = [:]
    ) {
      buffer = ""
      if name == "ValCurs" { dateString = attributes["Date"] }
      if name == "Valute" { code = ""; nominal = ""; value = "" }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
      buffer += string
    }

    func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
      let text = buffer.trimmingCharacters(in: .whitespacesAndNewlines)
      switch name {
      case "CharCode": code = text
      case "Nominal": nominal = text
      case "Value": value = text
      case "Valute":
        if let v = Double(value.replacingOccurrences(of: ",", with: ".")),
          let n = Double(nominal.replacingOccurrences(of: ",", with: ".")), n > 0
        {
          values[code] = v / n
        }
      default: break
      }
      buffer = ""
    }
  }
}
