import Foundation

struct Currency: Identifiable, Hashable, Codable {
    let id: String          // ISO 4217 code e.g. "USD"
    let name: String        // Full name
    let symbol: String      // Currency symbol
    let countryCode: String // ISO 3166-1 alpha-2 used to build flag emoji

    var flag: String {
        countryCode.unicodeScalars.reduce("") {
            $0 + (Unicode.Scalar($1.value + 127397).map(String.init) ?? "")
        }
    }

    // MARK: - Full 160+ currency list (sorted by ISO code)
    static let all: [Currency] = [
        Currency(id: "AED", name: "UAE Dirham",                       symbol: "د.إ", countryCode: "AE"),
        Currency(id: "AFN", name: "Afghan Afghani",                    symbol: "؋",   countryCode: "AF"),
        Currency(id: "ALL", name: "Albanian Lek",                      symbol: "L",   countryCode: "AL"),
        Currency(id: "AMD", name: "Armenian Dram",                     symbol: "֏",   countryCode: "AM"),
        Currency(id: "ANG", name: "Neth. Antillean Guilder",           symbol: "ƒ",   countryCode: "CW"),
        Currency(id: "AOA", name: "Angolan Kwanza",                    symbol: "Kz",  countryCode: "AO"),
        Currency(id: "ARS", name: "Argentine Peso",                    symbol: "$",   countryCode: "AR"),
        Currency(id: "AUD", name: "Australian Dollar",                 symbol: "A$",  countryCode: "AU"),
        Currency(id: "AWG", name: "Aruban Florin",                     symbol: "ƒ",   countryCode: "AW"),
        Currency(id: "AZN", name: "Azerbaijani Manat",                 symbol: "₼",   countryCode: "AZ"),

        Currency(id: "BAM", name: "Bosnia-Herzegovina Mark",           symbol: "KM",  countryCode: "BA"),
        Currency(id: "BBD", name: "Barbadian Dollar",                  symbol: "$",   countryCode: "BB"),
        Currency(id: "BDT", name: "Bangladeshi Taka",                  symbol: "৳",   countryCode: "BD"),
        Currency(id: "BGN", name: "Bulgarian Lev",                     symbol: "лв",  countryCode: "BG"),
        Currency(id: "BHD", name: "Bahraini Dinar",                    symbol: "BD",  countryCode: "BH"),
        Currency(id: "BIF", name: "Burundian Franc",                   symbol: "Fr",  countryCode: "BI"),
        Currency(id: "BMD", name: "Bermudian Dollar",                  symbol: "$",   countryCode: "BM"),
        Currency(id: "BND", name: "Brunei Dollar",                     symbol: "$",   countryCode: "BN"),
        Currency(id: "BOB", name: "Bolivian Boliviano",                symbol: "Bs",  countryCode: "BO"),
        Currency(id: "BRL", name: "Brazilian Real",                    symbol: "R$",  countryCode: "BR"),
        Currency(id: "BSD", name: "Bahamian Dollar",                   symbol: "$",   countryCode: "BS"),
        Currency(id: "BTN", name: "Bhutanese Ngultrum",                symbol: "Nu",  countryCode: "BT"),
        Currency(id: "BWP", name: "Botswanan Pula",                    symbol: "P",   countryCode: "BW"),
        Currency(id: "BYN", name: "Belarusian Ruble",                  symbol: "Br",  countryCode: "BY"),
        Currency(id: "BZD", name: "Belize Dollar",                     symbol: "$",   countryCode: "BZ"),

        Currency(id: "CAD", name: "Canadian Dollar",                   symbol: "CA$", countryCode: "CA"),
        Currency(id: "CDF", name: "Congolese Franc",                   symbol: "Fr",  countryCode: "CD"),
        Currency(id: "CHF", name: "Swiss Franc",                       symbol: "CHF", countryCode: "CH"),
        Currency(id: "CLP", name: "Chilean Peso",                      symbol: "$",   countryCode: "CL"),
        Currency(id: "CNY", name: "Chinese Yuan",                      symbol: "¥",   countryCode: "CN"),
        Currency(id: "COP", name: "Colombian Peso",                    symbol: "$",   countryCode: "CO"),
        Currency(id: "CRC", name: "Costa Rican Colón",                 symbol: "₡",   countryCode: "CR"),
        Currency(id: "CUP", name: "Cuban Peso",                        symbol: "$",   countryCode: "CU"),
        Currency(id: "CVE", name: "Cape Verdean Escudo",               symbol: "$",   countryCode: "CV"),
        Currency(id: "CZK", name: "Czech Koruna",                      symbol: "Kč",  countryCode: "CZ"),

        Currency(id: "DJF", name: "Djiboutian Franc",                  symbol: "Fr",  countryCode: "DJ"),
        Currency(id: "DKK", name: "Danish Krone",                      symbol: "kr",  countryCode: "DK"),
        Currency(id: "DOP", name: "Dominican Peso",                    symbol: "$",   countryCode: "DO"),
        Currency(id: "DZD", name: "Algerian Dinar",                    symbol: "DA",  countryCode: "DZ"),

        Currency(id: "EGP", name: "Egyptian Pound",                    symbol: "£",   countryCode: "EG"),
        Currency(id: "ERN", name: "Eritrean Nakfa",                    symbol: "Nfk", countryCode: "ER"),
        Currency(id: "ETB", name: "Ethiopian Birr",                    symbol: "Br",  countryCode: "ET"),
        Currency(id: "EUR", name: "Euro",                              symbol: "€",   countryCode: "EU"),

        Currency(id: "FJD", name: "Fijian Dollar",                     symbol: "$",   countryCode: "FJ"),
        Currency(id: "FKP", name: "Falkland Islands Pound",            symbol: "£",   countryCode: "FK"),

        Currency(id: "GBP", name: "British Pound Sterling",            symbol: "£",   countryCode: "GB"),
        Currency(id: "GEL", name: "Georgian Lari",                     symbol: "₾",   countryCode: "GE"),
        Currency(id: "GHS", name: "Ghanaian Cedi",                     symbol: "₵",   countryCode: "GH"),
        Currency(id: "GIP", name: "Gibraltar Pound",                   symbol: "£",   countryCode: "GI"),
        Currency(id: "GMD", name: "Gambian Dalasi",                    symbol: "D",   countryCode: "GM"),
        Currency(id: "GNF", name: "Guinean Franc",                     symbol: "Fr",  countryCode: "GN"),
        Currency(id: "GTQ", name: "Guatemalan Quetzal",                symbol: "Q",   countryCode: "GT"),
        Currency(id: "GYD", name: "Guyanaese Dollar",                  symbol: "$",   countryCode: "GY"),

        Currency(id: "HKD", name: "Hong Kong Dollar",                  symbol: "HK$", countryCode: "HK"),
        Currency(id: "HNL", name: "Honduran Lempira",                  symbol: "L",   countryCode: "HN"),
        Currency(id: "HRK", name: "Croatian Kuna",                     symbol: "kn",  countryCode: "HR"),
        Currency(id: "HTG", name: "Haitian Gourde",                    symbol: "G",   countryCode: "HT"),
        Currency(id: "HUF", name: "Hungarian Forint",                  symbol: "Ft",  countryCode: "HU"),

        Currency(id: "IDR", name: "Indonesian Rupiah",                 symbol: "Rp",  countryCode: "ID"),
        Currency(id: "ILS", name: "Israeli Shekel",                    symbol: "₪",   countryCode: "IL"),
        Currency(id: "IMP", name: "Isle of Man Pound",                 symbol: "£",   countryCode: "IM"),
        Currency(id: "INR", name: "Indian Rupee",                      symbol: "₹",   countryCode: "IN"),
        Currency(id: "IQD", name: "Iraqi Dinar",                       symbol: "ID",  countryCode: "IQ"),
        Currency(id: "IRR", name: "Iranian Rial",                      symbol: "﷼",   countryCode: "IR"),
        Currency(id: "ISK", name: "Icelandic Króna",                   symbol: "kr",  countryCode: "IS"),

        Currency(id: "JEP", name: "Jersey Pound",                      symbol: "£",   countryCode: "JE"),
        Currency(id: "JMD", name: "Jamaican Dollar",                   symbol: "$",   countryCode: "JM"),
        Currency(id: "JOD", name: "Jordanian Dinar",                   symbol: "JD",  countryCode: "JO"),
        Currency(id: "JPY", name: "Japanese Yen",                      symbol: "¥",   countryCode: "JP"),

        Currency(id: "KES", name: "Kenyan Shilling",                   symbol: "Ksh", countryCode: "KE"),
        Currency(id: "KGS", name: "Kyrgystani Som",                    symbol: "с",   countryCode: "KG"),
        Currency(id: "KHR", name: "Cambodian Riel",                    symbol: "៛",   countryCode: "KH"),
        Currency(id: "KMF", name: "Comorian Franc",                    symbol: "Fr",  countryCode: "KM"),
        Currency(id: "KPW", name: "North Korean Won",                  symbol: "₩",   countryCode: "KP"),
        Currency(id: "KRW", name: "South Korean Won",                  symbol: "₩",   countryCode: "KR"),
        Currency(id: "KWD", name: "Kuwaiti Dinar",                     symbol: "KD",  countryCode: "KW"),
        Currency(id: "KYD", name: "Cayman Islands Dollar",             symbol: "$",   countryCode: "KY"),
        Currency(id: "KZT", name: "Kazakhstani Tenge",                 symbol: "₸",   countryCode: "KZ"),

        Currency(id: "LAK", name: "Laotian Kip",                       symbol: "₭",   countryCode: "LA"),
        Currency(id: "LBP", name: "Lebanese Pound",                    symbol: "£",   countryCode: "LB"),
        Currency(id: "LKR", name: "Sri Lankan Rupee",                  symbol: "₨",   countryCode: "LK"),
        Currency(id: "LRD", name: "Liberian Dollar",                   symbol: "$",   countryCode: "LR"),
        Currency(id: "LSL", name: "Lesotho Loti",                      symbol: "L",   countryCode: "LS"),
        Currency(id: "LYD", name: "Libyan Dinar",                      symbol: "LD",  countryCode: "LY"),

        Currency(id: "MAD", name: "Moroccan Dirham",                   symbol: "MAD", countryCode: "MA"),
        Currency(id: "MDL", name: "Moldovan Leu",                      symbol: "L",   countryCode: "MD"),
        Currency(id: "MGA", name: "Malagasy Ariary",                   symbol: "Ar",  countryCode: "MG"),
        Currency(id: "MKD", name: "Macedonian Denar",                  symbol: "ден", countryCode: "MK"),
        Currency(id: "MMK", name: "Myanmar Kyat",                      symbol: "K",   countryCode: "MM"),
        Currency(id: "MNT", name: "Mongolian Tögrög",                  symbol: "₮",   countryCode: "MN"),
        Currency(id: "MOP", name: "Macanese Pataca",                   symbol: "P",   countryCode: "MO"),
        Currency(id: "MRU", name: "Mauritanian Ouguiya",               symbol: "UM",  countryCode: "MR"),
        Currency(id: "MUR", name: "Mauritian Rupee",                   symbol: "₨",   countryCode: "MU"),
        Currency(id: "MVR", name: "Maldivian Rufiyaa",                 symbol: "ރ",   countryCode: "MV"),
        Currency(id: "MWK", name: "Malawian Kwacha",                   symbol: "MK",  countryCode: "MW"),
        Currency(id: "MXN", name: "Mexican Peso",                      symbol: "$",   countryCode: "MX"),
        Currency(id: "MYR", name: "Malaysian Ringgit",                 symbol: "RM",  countryCode: "MY"),
        Currency(id: "MZN", name: "Mozambican Metical",                symbol: "MT",  countryCode: "MZ"),

        Currency(id: "NAD", name: "Namibian Dollar",                   symbol: "$",   countryCode: "NA"),
        Currency(id: "NGN", name: "Nigerian Naira",                    symbol: "₦",   countryCode: "NG"),
        Currency(id: "NIO", name: "Nicaraguan Córdoba",                symbol: "C$",  countryCode: "NI"),
        Currency(id: "NOK", name: "Norwegian Krone",                   symbol: "kr",  countryCode: "NO"),
        Currency(id: "NPR", name: "Nepalese Rupee",                    symbol: "₨",   countryCode: "NP"),
        Currency(id: "NZD", name: "New Zealand Dollar",                symbol: "NZ$", countryCode: "NZ"),

        Currency(id: "OMR", name: "Omani Rial",                        symbol: "﷼",   countryCode: "OM"),

        Currency(id: "PAB", name: "Panamanian Balboa",                 symbol: "B/.", countryCode: "PA"),
        Currency(id: "PEN", name: "Peruvian Sol",                      symbol: "S/.", countryCode: "PE"),
        Currency(id: "PGK", name: "Papua New Guinean Kina",            symbol: "K",   countryCode: "PG"),
        Currency(id: "PHP", name: "Philippine Peso",                   symbol: "₱",   countryCode: "PH"),
        Currency(id: "PKR", name: "Pakistani Rupee",                   symbol: "₨",   countryCode: "PK"),
        Currency(id: "PLN", name: "Polish Zloty",                      symbol: "zł",  countryCode: "PL"),
        Currency(id: "PYG", name: "Paraguayan Guarani",                symbol: "₲",   countryCode: "PY"),

        Currency(id: "QAR", name: "Qatari Rial",                       symbol: "﷼",   countryCode: "QA"),

        Currency(id: "RON", name: "Romanian Leu",                      symbol: "lei", countryCode: "RO"),
        Currency(id: "RSD", name: "Serbian Dinar",                     symbol: "din", countryCode: "RS"),
        Currency(id: "RUB", name: "Russian Ruble",                     symbol: "₽",   countryCode: "RU"),
        Currency(id: "RWF", name: "Rwandan Franc",                     symbol: "Fr",  countryCode: "RW"),

        Currency(id: "SAR", name: "Saudi Riyal",                       symbol: "﷼",   countryCode: "SA"),
        Currency(id: "SBD", name: "Solomon Islands Dollar",            symbol: "$",   countryCode: "SB"),
        Currency(id: "SCR", name: "Seychellois Rupee",                 symbol: "₨",   countryCode: "SC"),
        Currency(id: "SDG", name: "Sudanese Pound",                    symbol: "£",   countryCode: "SD"),
        Currency(id: "SEK", name: "Swedish Krona",                     symbol: "kr",  countryCode: "SE"),
        Currency(id: "SGD", name: "Singapore Dollar",                  symbol: "S$",  countryCode: "SG"),
        Currency(id: "SHP", name: "Saint Helena Pound",                symbol: "£",   countryCode: "SH"),
        Currency(id: "SLL", name: "Sierra Leonean Leone",              symbol: "Le",  countryCode: "SL"),
        Currency(id: "SOS", name: "Somali Shilling",                   symbol: "Sh",  countryCode: "SO"),
        Currency(id: "SRD", name: "Surinamese Dollar",                 symbol: "$",   countryCode: "SR"),
        Currency(id: "SSP", name: "South Sudanese Pound",              symbol: "£",   countryCode: "SS"),
        Currency(id: "STN", name: "São Tomé Dobra",                    symbol: "Db",  countryCode: "ST"),
        Currency(id: "SVC", name: "Salvadoran Colón",                  symbol: "₡",   countryCode: "SV"),
        Currency(id: "SYP", name: "Syrian Pound",                      symbol: "£",   countryCode: "SY"),
        Currency(id: "SZL", name: "Swazi Lilangeni",                   symbol: "L",   countryCode: "SZ"),

        Currency(id: "THB", name: "Thai Baht",                         symbol: "฿",   countryCode: "TH"),
        Currency(id: "TJS", name: "Tajikistani Somoni",                symbol: "SM",  countryCode: "TJ"),
        Currency(id: "TMT", name: "Turkmenistani Manat",               symbol: "T",   countryCode: "TM"),
        Currency(id: "TND", name: "Tunisian Dinar",                    symbol: "DT",  countryCode: "TN"),
        Currency(id: "TOP", name: "Tongan Paʻanga",                    symbol: "T$",  countryCode: "TO"),
        Currency(id: "TRY", name: "Turkish Lira",                      symbol: "₺",   countryCode: "TR"),
        Currency(id: "TTD", name: "Trinidad & Tobago Dollar",          symbol: "$",   countryCode: "TT"),
        Currency(id: "TWD", name: "New Taiwan Dollar",                 symbol: "NT$", countryCode: "TW"),
        Currency(id: "TZS", name: "Tanzanian Shilling",                symbol: "Sh",  countryCode: "TZ"),

        Currency(id: "UAH", name: "Ukrainian Hryvnia",                 symbol: "₴",   countryCode: "UA"),
        Currency(id: "UGX", name: "Ugandan Shilling",                  symbol: "Sh",  countryCode: "UG"),
        Currency(id: "USD", name: "US Dollar",                         symbol: "$",   countryCode: "US"),
        Currency(id: "UYU", name: "Uruguayan Peso",                    symbol: "$",   countryCode: "UY"),
        Currency(id: "UZS", name: "Uzbekistani Som",                   symbol: "лв",  countryCode: "UZ"),

        Currency(id: "VES", name: "Venezuelan Bolívar",                symbol: "Bs",  countryCode: "VE"),
        Currency(id: "VND", name: "Vietnamese Dong",                   symbol: "₫",   countryCode: "VN"),
        Currency(id: "VUV", name: "Vanuatu Vatu",                      symbol: "Vt",  countryCode: "VU"),

        Currency(id: "WST", name: "Samoan Tala",                       symbol: "T",   countryCode: "WS"),

        Currency(id: "XAF", name: "Central African CFA Franc",         symbol: "Fr",  countryCode: "CM"),
        Currency(id: "XCD", name: "East Caribbean Dollar",             symbol: "$",   countryCode: "AG"),
        Currency(id: "XOF", name: "West African CFA Franc",            symbol: "Fr",  countryCode: "SN"),
        Currency(id: "XPF", name: "CFP Franc",                         symbol: "Fr",  countryCode: "PF"),

        Currency(id: "YER", name: "Yemeni Rial",                       symbol: "﷼",   countryCode: "YE"),

        Currency(id: "ZAR", name: "South African Rand",                symbol: "R",   countryCode: "ZA"),
        Currency(id: "ZMW", name: "Zambian Kwacha",                    symbol: "ZK",  countryCode: "ZM"),
        Currency(id: "ZWL", name: "Zimbabwean Dollar",                 symbol: "$",   countryCode: "ZW"),
    ]

    static func find(by id: String) -> Currency {
        all.first { $0.id == id } ?? all.first { $0.id == "USD" }!
    }

    // Currencies grouped alphabetically by ISO code (for picker sections)
    static var sections: [(header: String, items: [Currency])] {
        let sorted = all.sorted { $0.id < $1.id }
        var result: [(String, [Currency])] = []
        var current: (String, [Currency])? = nil
        for c in sorted {
            let letter = String(c.id.prefix(1))
            if current?.0 == letter {
                current!.1.append(c)
            } else {
                if let prev = current { result.append(prev) }
                current = (letter, [c])
            }
        }
        if let last = current { result.append(last) }
        return result
    }
}
