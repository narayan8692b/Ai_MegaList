import SwiftUI

struct SupportedLanguage: Identifiable, Hashable {
    let code: String
    let name: String
    let flag: String

    var id: String { code }

    static let all: [SupportedLanguage] = [
        SupportedLanguage(code: "EN", name: "English",    flag: "🇺🇸"),
        SupportedLanguage(code: "ES", name: "Spanish",    flag: "🇪🇸"),
        SupportedLanguage(code: "FR", name: "French",     flag: "🇫🇷"),
        SupportedLanguage(code: "DE", name: "German",     flag: "🇩🇪"),
        SupportedLanguage(code: "IT", name: "Italian",    flag: "🇮🇹"),
        SupportedLanguage(code: "PT", name: "Portuguese", flag: "🇵🇹"),
        SupportedLanguage(code: "NL", name: "Dutch",      flag: "🇳🇱"),
        SupportedLanguage(code: "RU", name: "Russian",    flag: "🇷🇺"),
        SupportedLanguage(code: "JA", name: "Japanese",   flag: "🇯🇵"),
        SupportedLanguage(code: "KO", name: "Korean",     flag: "🇰🇷"),
        SupportedLanguage(code: "ZH", name: "Chinese",    flag: "🇨🇳"),
        SupportedLanguage(code: "AR", name: "Arabic",     flag: "🇸🇦"),
        SupportedLanguage(code: "HI", name: "Hindi",      flag: "🇮🇳"),
        SupportedLanguage(code: "TR", name: "Turkish",    flag: "🇹🇷"),
        SupportedLanguage(code: "PL", name: "Polish",     flag: "🇵🇱")
    ]

    static func named(_ code: String) -> SupportedLanguage {
        all.first { $0.code == code } ?? all[0]
    }
}

struct LanguagePickerView: View {
    @AppStorage("preferredLanguageCode") private var selectedCode: String = "EN"
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { lang in
                    Button {
                        selectedCode = lang.code
                        dismiss()
                    } label: {
                        HStack {
                            Text(lang.flag).font(.title3)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(lang.name)
                                    .foregroundStyle(Color.brandInk)
                                Text(lang.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if lang.code == selectedCode {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.antiqueGold)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search languages…")
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var filtered: [SupportedLanguage] {
        guard !query.isEmpty else { return SupportedLanguage.all }
        let q = query.lowercased()
        return SupportedLanguage.all.filter {
            $0.name.lowercased().contains(q) || $0.code.lowercased().contains(q)
        }
    }
}

#Preview {
    LanguagePickerView()
}
