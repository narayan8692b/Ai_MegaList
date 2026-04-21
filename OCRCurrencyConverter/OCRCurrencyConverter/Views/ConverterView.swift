import SwiftUI

struct ConverterView: View {
    @StateObject private var vm = ConverterViewModel()
    @EnvironmentObject private var exchangeService: ExchangeRateService
    @State private var showPicker = false
    @FocusState private var amountFocused: Bool

    var body: some View {
        NavigationView {
            List {
                // Add currency button
                Button {
                    showPicker = true
                } label: {
                    Text("Add currency")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundColor(.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 1.5)
                        )
                }
                .listRowSeparator(.hidden)

                // Currency rows
                ForEach(vm.currencies) { currency in
                    CurrencyRow(
                        currency: currency,
                        isBase: currency.id == vm.baseCurrencyId,
                        baseAmountText: $vm.baseAmountText,
                        convertedAmount: convertedAmount(for: currency),
                        rateText: rateText(for: currency),
                        amountFocused: $amountFocused
                    ) {
                        vm.setBase(currency)
                        amountFocused = true
                    }
                }
                .onDelete { vm.removeCurrencies(at: $0) }
                .onMove   { vm.moveCurrencies(from: $0, to: $1) }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Currency")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if amountFocused {
                        Button("Done") { amountFocused = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            CurrencySelectorView(
                mode: .multiSelect(
                    existing: Set(vm.currencies.map(\.id)),
                    onToggle: { currency in
                        if vm.currencies.contains(where: { $0.id == currency.id }) {
                            vm.currencies.removeAll { $0.id == currency.id }
                        } else {
                            vm.addCurrency(currency)
                        }
                    }
                )
            )
        }
    }

    // MARK: - Helpers

    private func convertedAmount(for currency: Currency) -> Double? {
        if currency.id == vm.baseCurrencyId { return vm.baseAmount }
        return exchangeService.convert(amount: vm.baseAmount,
                                       from: vm.baseCurrencyId,
                                       to: currency.id)
    }

    private func rateText(for currency: Currency) -> String {
        guard currency.id != vm.baseCurrencyId,
              let rate = exchangeService.convert(amount: 1,
                                                 from: vm.baseCurrencyId,
                                                 to: currency.id)
        else { return "" }
        return "1 \(vm.baseCurrencyId) = \(String(format: "%.4f", rate)) \(currency.id)"
    }
}

// MARK: - Currency Row

private struct CurrencyRow: View {
    let currency: Currency
    let isBase: Bool
    @Binding var baseAmountText: String
    let convertedAmount: Double?
    let rateText: String
    var amountFocused: FocusState<Bool>.Binding
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Flag
                Text(currency.flag)
                    .font(.system(size: 32))
                    .frame(width: 40)

                // Code + Name
                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.id)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(currency.name)
                        .font(.body)
                        .lineLimit(1)
                }

                Spacer()

                // Amount + rate
                VStack(alignment: .trailing, spacing: 2) {
                    if isBase {
                        TextField("0", text: $baseAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .font(.title2.bold())
                            .focused(amountFocused)
                            .frame(minWidth: 80)
                    } else if let amount = convertedAmount {
                        Text(formatted(amount, symbol: currency.symbol))
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    if !rateText.isEmpty {
                        Text(rateText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .listRowBackground(isBase ? Color(.systemBlue).opacity(0.06) : Color(.systemBackground))
    }

    private func formatted(_ amount: Double, symbol: String) -> String {
        let s = String(format: "%.2f", amount)
        return "\(symbol) \(s)"
    }
}
