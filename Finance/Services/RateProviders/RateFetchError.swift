import Foundation

enum RateFetchError: LocalizedError {
  case network(String)
  case badStatus(Int)
  case notFound
  case malformed
  case missingCurrency(String)

  var errorDescription: String? {
    switch self {
    case .network(let message): "Не удалось связаться с сервером: \(message)"
    case .badStatus(let code): "Сервер ответил с ошибкой (HTTP \(code))."
    case .notFound: "Курс на выбранную дату не найден."
    case .malformed: "Не удалось разобрать ответ сервера."
    case .missingCurrency(let code): "В ответе нет курса \(code)."
    }
  }
}
