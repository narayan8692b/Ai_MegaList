import SwiftUI

struct LanguagePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    let selectedCode: String
    let onSelect: (String) -> Void

    private var filtered: [Language] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty { return Languages.all }
        return Languages.all.filter { $0.name.lowercased().contains(q) || $0.code.contains(q) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                VStack(spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Theme.textTertiary)
                        TextField("Search languages...", text: $query)
                            .foregroundColor(Theme.textPrimary)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .cardBackground()
                    .padding(.horizontal)
                    .padding(.top, 8)

                    List {
                        ForEach(filtered) { language in
                            Button {
                                onSelect(language.code)
                                dismiss()
                            } label: {
                                HStack(spacing: 12) {
                                    Text(language.flag).font(.title3)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(language.name)
                                            .foregroundColor(Theme.textPrimary)
                                            .font(.body.weight(.medium))
                                        Text(language.code.uppercased())
                                            .font(.caption2.weight(.semibold))
                                            .foregroundColor(Theme.textTertiary)
                                    }
                                    Spacer()
                                    if language.code == selectedCode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(Theme.accent)
                                    }
                                }
                                .padding(.vertical, 6)
                            }
                            .listRowBackground(Theme.background)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Select Language")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Theme.textPrimary)
                    }
                }
            }
        }
    }
}
