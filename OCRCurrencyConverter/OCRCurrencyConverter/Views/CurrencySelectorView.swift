import SwiftUI

struct CurrencySelectorView: View {
    @Binding var selected: Currency
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [Currency] {
        query.isEmpty ? Currency.all : Currency.all.filter {
            $0.id.localizedCaseInsensitiveContains(query) ||
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationView {
            List(filtered) { currency in
                Button {
                    selected = currency
                    dismiss()
                } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(currency.id)
                                .font(.headline)
                            Text(currency.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(currency.symbol)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        if currency.id == selected.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .foregroundColor(.primary)
            }
            .searchable(text: $query, prompt: "Search currencies")
            .navigationTitle("Select Currency")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
