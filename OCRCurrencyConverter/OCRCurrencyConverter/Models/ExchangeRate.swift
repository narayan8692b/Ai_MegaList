import Foundation

struct ExchangeRateResponse: Codable {
    let result: String
    let baseCode: String
    let rates: [String: Double]

    enum CodingKeys: String, CodingKey {
        case result
        case baseCode = "base_code"
        case rates
    }
}

struct ConversionResult {
    let originalAmount: Double
    let convertedAmount: Double
    let fromCurrency: Currency
    let toCurrency: Currency

    var formattedResult: String {
        "\(String(format: "%.2f", originalAmount)) \(fromCurrency.symbol) = \(String(format: "%.2f", convertedAmount)) \(toCurrency.symbol)"
    }
}
