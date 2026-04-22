import SwiftUI

// MARK: - Mode

enum CurrencySelectorMode {
    /// Tap to select one currency, then auto-dismiss.
    case singleSelect(current: String, onSelect: (Currency) -> Void)
    /// Tap to add/remove currencies; shows checkmarks for IDs in `existing`.
    case multiSelect(existing: Set<String>, onToggle: (Currency) -> Void)
}

// MARK: - View

struct CurrencySelectorView: View {
    let mode: CurrencySelectorMode
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var existingIds: Set<String> {
        if case .multiSelect(let ids, _) = mode { return ids }
        return []
    }
    private var currentId: String {
        if case .singleSelect(let id, _) = mode { return id }
        return ""
    }

    private var filteredSections: [(header: String, items: [Currency])] {
        if query.isEmpty { return Currency.sections }
        let q = query.lowercased()
        let matched = Currency.all
            .filter { $0.id.lowercased().contains(q) || $0.name.lowercased().contains(q) }
            .sorted { $0.id < $1.id }
        guard !matched.isEmpty else { return [] }
        return [("", matched)]
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredSections, id: \.header) { section in
                    Section(header: sectionHeader(section.header)) {
                        ForEach(section.items) { currency in
                            row(for: currency)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $query, prompt: "Search...")
            .navigationTitle("Select currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        if text.isEmpty {
            EmptyView()
        } else {
            Text(text)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }

    private func row(for currency: Currency) -> some View {
        let isSelected = existingIds.contains(currency.id) || currency.id == currentId

        return Button {
            switch mode {
            case .singleSelect(_, let onSelect):
                onSelect(currency)
                dismiss()
            case .multiSelect(_, let onToggle):
                onToggle(currency)
            }
        } label: {
            HStack(spacing: 12) {

                // Flag inside rounded square container
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 42, height: 42)
                    if currency.flag.isEmpty {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                            .frame(width: 42, height: 42)
                    }
                    Text(currency.flag.isEmpty ? "🏳" : currency.flag)
                        .font(.system(size: 26))
                }

                // Code + Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currency.name)
                        .font(.body)
                        .foregroundColor(.primary)
                }

                Spacer()

                // Checkmark (filled circle to match screenshot)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
