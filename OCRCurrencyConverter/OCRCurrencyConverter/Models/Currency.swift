import Foundation

struct Currency: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let symbol: String

    static let all: [Currency] = [
        Currency(id: "USD", name: "US Dollar",           symbol: "$"),
        Currency(id: "EUR", name: "Euro",                symbol: "€"),
        Currency(id: "GBP", name: "British Pound",       symbol: "£"),
        Currency(id: "JPY", name: "Japanese Yen",        symbol: "¥"),
        Currency(id: "CAD", name: "Canadian Dollar",     symbol: "CA$"),
        Currency(id: "AUD", name: "Australian Dollar",   symbol: "A$"),
        Currency(id: "CHF", name: "Swiss Franc",         symbol: "CHF"),
        Currency(id: "CNY", name: "Chinese Yuan",        symbol: "¥"),
        Currency(id: "INR", name: "Indian Rupee",        symbol: "₹"),
        Currency(id: "MXN", name: "Mexican Peso",        symbol: "MX$"),
        Currency(id: "BRL", name: "Brazilian Real",      symbol: "R$"),
        Currency(id: "KRW", name: "South Korean Won",    symbol: "₩"),
        Currency(id: "SGD", name: "Singapore Dollar",    symbol: "S$"),
        Currency(id: "HKD", name: "Hong Kong Dollar",    symbol: "HK$"),
        Currency(id: "NOK", name: "Norwegian Krone",     symbol: "kr"),
        Currency(id: "SEK", name: "Swedish Krona",       symbol: "kr"),
        Currency(id: "DKK", name: "Danish Krone",        symbol: "kr"),
        Currency(id: "NZD", name: "New Zealand Dollar",  symbol: "NZ$"),
        Currency(id: "ZAR", name: "South African Rand",  symbol: "R"),
        Currency(id: "TRY", name: "Turkish Lira",        symbol: "₺"),
        Currency(id: "PLN", name: "Polish Zloty",        symbol: "zł"),
        Currency(id: "CZK", name: "Czech Koruna",        symbol: "Kč"),
        Currency(id: "HUF", name: "Hungarian Forint",    symbol: "Ft"),
        Currency(id: "ILS", name: "Israeli Shekel",      symbol: "₪"),
        Currency(id: "AED", name: "UAE Dirham",          symbol: "د.إ"),
        Currency(id: "SAR", name: "Saudi Riyal",         symbol: "﷼"),
        Currency(id: "THB", name: "Thai Baht",           symbol: "฿"),
        Currency(id: "MYR", name: "Malaysian Ringgit",   symbol: "RM"),
        Currency(id: "IDR", name: "Indonesian Rupiah",   symbol: "Rp"),
        Currency(id: "RUB", name: "Russian Ruble",       symbol: "₽"),
    ]

    static func find(by id: String) -> Currency {
        all.first { $0.id == id } ?? all[0]
    }
}
