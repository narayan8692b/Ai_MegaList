import Foundation

struct Language: Identifiable, Hashable {
    var id: String { code }
    let name: String
    let code: String
    let flag: String
}

enum Languages {
    static let automatic = Language(name: "Automatic", code: "auto", flag: "🌐")

    static let all: [Language] = [
        automatic,
        Language(name: "English", code: "en", flag: "🇺🇸"),
        Language(name: "German", code: "de", flag: "🇩🇪"),
        Language(name: "Spanish", code: "es", flag: "🇪🇸"),
        Language(name: "Afrikaans", code: "af", flag: "🇿🇦"),
        Language(name: "Arabic", code: "ar", flag: "🇸🇦"),
        Language(name: "Armenian", code: "hy", flag: "🇦🇲"),
        Language(name: "Azerbaijani", code: "az", flag: "🇦🇿"),
        Language(name: "Belarusian", code: "be", flag: "🇧🇾"),
        Language(name: "Bosnian", code: "bs", flag: "🇧🇦"),
        Language(name: "Bulgarian", code: "bg", flag: "🇧🇬"),
        Language(name: "Catalan", code: "ca", flag: "🇪🇸"),
        Language(name: "Chinese", code: "zh", flag: "🇨🇳"),
        Language(name: "Croatian", code: "hr", flag: "🇭🇷"),
        Language(name: "Czech", code: "cs", flag: "🇨🇿"),
        Language(name: "Danish", code: "da", flag: "🇩🇰"),
        Language(name: "Dutch", code: "nl", flag: "🇳🇱"),
        Language(name: "Estonian", code: "et", flag: "🇪🇪"),
        Language(name: "Finnish", code: "fi", flag: "🇫🇮"),
        Language(name: "French", code: "fr", flag: "🇫🇷"),
        Language(name: "Galician", code: "gl", flag: "🇪🇸"),
        Language(name: "Greek", code: "el", flag: "🇬🇷"),
        Language(name: "Hebrew", code: "he", flag: "🇮🇱"),
        Language(name: "Hindi", code: "hi", flag: "🇮🇳"),
        Language(name: "Hungarian", code: "hu", flag: "🇭🇺"),
        Language(name: "Icelandic", code: "is", flag: "🇮🇸"),
        Language(name: "Indonesian", code: "id", flag: "🇮🇩"),
        Language(name: "Italian", code: "it", flag: "🇮🇹"),
        Language(name: "Japanese", code: "ja", flag: "🇯🇵"),
        Language(name: "Kannada", code: "kn", flag: "🇮🇳"),
        Language(name: "Kazakh", code: "kk", flag: "🇰🇿"),
        Language(name: "Korean", code: "ko", flag: "🇰🇷"),
        Language(name: "Latvian", code: "lv", flag: "🇱🇻"),
        Language(name: "Lithuanian", code: "lt", flag: "🇱🇹"),
        Language(name: "Macedonian", code: "mk", flag: "🇲🇰"),
        Language(name: "Malay", code: "ms", flag: "🇲🇾"),
        Language(name: "Marathi", code: "mr", flag: "🇮🇳"),
        Language(name: "Maori", code: "mi", flag: "🇳🇿"),
        Language(name: "Nepali", code: "ne", flag: "🇳🇵"),
        Language(name: "Norwegian", code: "no", flag: "🇳🇴"),
        Language(name: "Persian", code: "fa", flag: "🇮🇷"),
        Language(name: "Polish", code: "pl", flag: "🇵🇱"),
        Language(name: "Portuguese", code: "pt", flag: "🇵🇹"),
        Language(name: "Romanian", code: "ro", flag: "🇷🇴"),
        Language(name: "Russian", code: "ru", flag: "🇷🇺"),
        Language(name: "Serbian", code: "sr", flag: "🇷🇸"),
        Language(name: "Slovak", code: "sk", flag: "🇸🇰"),
        Language(name: "Slovenian", code: "sl", flag: "🇸🇮"),
        Language(name: "Swahili", code: "sw", flag: "🇰🇪"),
        Language(name: "Swedish", code: "sv", flag: "🇸🇪"),
        Language(name: "Tagalog", code: "tl", flag: "🇵🇭"),
        Language(name: "Tamil", code: "ta", flag: "🇮🇳"),
        Language(name: "Thai", code: "th", flag: "🇹🇭"),
        Language(name: "Turkish", code: "tr", flag: "🇹🇷"),
        Language(name: "Ukrainian", code: "uk", flag: "🇺🇦"),
        Language(name: "Urdu", code: "ur", flag: "🇵🇰"),
        Language(name: "Vietnamese", code: "vi", flag: "🇻🇳"),
        Language(name: "Welsh", code: "cy", flag: "🇬🇧")
    ]

    static func named(_ code: String) -> Language {
        all.first(where: { $0.code == code }) ?? automatic
    }
}
