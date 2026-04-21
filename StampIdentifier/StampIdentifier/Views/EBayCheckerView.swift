import SwiftUI

struct EBayCheckerView: View {
    let piece: Jewelry
    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var priceText: String = ""
    @State private var isChecking = false
    @State private var result: EBayListingCheck?
    @State private var errorMessage: String?

    private let checker: EBayPriceChecking = MockEBayPriceCheckingService()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    subjectCard
                    listingForm
                    if let result {
                        resultCard(for: result)
                    }
                }
                .padding()
            }
            .background(Color.jewelryCream.ignoresSafeArea())
            .navigationTitle("Check eBay Listing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            if title.isEmpty { title = piece.name }
        }
    }

    // MARK: Subviews

    private var subjectCard: some View {
        HStack(spacing: 12) {
            heroImage
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(piece.name).font(.subheadline.weight(.semibold)).lineLimit(2)
                Text("Fair value: \(piece.estimatedValueDisplay)")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        )
    }

    @ViewBuilder
    private var heroImage: some View {
        if let data = piece.imageData, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill()
        } else {
            ZStack {
                Color.jewelryGold.opacity(0.12)
                Image(systemName: "sparkles").foregroundStyle(Color.jewelryGold)
            }
        }
    }

    private var listingForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Paste the listing details")
                .font(.headline)
                .foregroundStyle(Color.brandInk)
            TextField("Listing title", text: $title, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...4)
            TextField("Asking price (USD)", text: $priceText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote).foregroundStyle(.red)
            }

            Button {
                Task { await runCheck() }
            } label: {
                if isChecking {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    Label("Check Fair Price", systemImage: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.jewelryGold)
            .disabled(isChecking)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private func resultCard(for check: EBayListingCheck) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(verdictColor(for: check))
                Text(check.verdict)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.brandInk)
                Spacer()
                Text("\(Int(check.confidence * 100))% confidence")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.jewelryGold.opacity(0.15)))
                    .foregroundStyle(Color.jewelryGold)
            }
            Text(check.verdictDetail)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(verdictColor(for: check))
            Divider()
            priceRow(label: "Asking price", value: check.listingPrice)
            priceRow(label: "Fair price", value: check.fairPrice)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
    }

    private func priceRow(label: String, value: Double) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(CurrencyFormatter.usd.string(from: NSNumber(value: value)) ?? "$\(Int(value))")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.brandInk)
        }
        .font(.subheadline)
    }

    private func verdictColor(for check: EBayListingCheck) -> Color {
        switch check.verdict {
        case "Fair Price":   return Color.green.opacity(0.9)
        case "Market Price": return Color.jewelryGold
        default:             return Color.red.opacity(0.85)
        }
    }

    // MARK: Logic

    private func runCheck() async {
        errorMessage = nil
        result = nil
        let cleaned = priceText
            .replacingOccurrences(of: "$", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)
        guard let price = Double(cleaned), price > 0 else {
            errorMessage = "Enter a valid listing price."
            return
        }
        let titleTrimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !titleTrimmed.isEmpty else {
            errorMessage = "Enter the listing title."
            return
        }
        isChecking = true
        defer { isChecking = false }
        do {
            result = try await checker.check(title: titleTrimmed, price: price)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    EBayCheckerView(piece: .sampleBaroquePearl)
}
