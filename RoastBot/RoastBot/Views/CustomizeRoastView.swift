import SwiftUI

struct CustomizeRoastView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    let image: UIImage

    @State private var config = RoastConfig()
    @State private var isGenerating = false
    @State private var error: String?
    @State private var results: [RoastResult] = []
    @State private var navigateToResults = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {

                    // Photo thumbnail
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)

                    // Intensity
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Intensity")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(config.intensityPercent)%")
                                .font(.headline.bold())
                                .foregroundColor(.orange)
                        }

                        Slider(value: $config.intensity, in: 0...1)
                            .tint(.orange)

                        HStack {
                            Text("😇 Mild")
                            Spacer()
                            Text("☢️ Nuclear")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Style picker
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Style")
                            .font(.headline)
                            .foregroundColor(.white)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(RoastStyle.allCases) { style in
                                    StyleChip(style: style, isSelected: config.style == style) {
                                        config.style = style
                                    }
                                }
                            }
                            .padding(.horizontal, 2)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Count picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Number of Roasts")
                            .font(.headline)
                            .foregroundColor(.white)

                        HStack(spacing: 12) {
                            ForEach([1, 3, 5], id: \.self) { count in
                                Button {
                                    config.count = count
                                } label: {
                                    Text("\(count)")
                                        .font(.title3.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(config.count == count ? Color.orange : Color.white.opacity(0.1))
                                        .foregroundColor(config.count == count ? .black : .white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Error
                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // Generate button
                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .tint(.black)
                                Text("Roasting...")
                            } else {
                                Image(systemName: "flame.fill")
                                Text("Generate Roasts")
                            }
                        }
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isGenerating
                                ? Color.gray
                                : LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundColor(isGenerating ? .white.opacity(0.6) : .white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: .orange.opacity(0.4), radius: 10)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 16)
            }
        }
        .navigationTitle("Customize Roast")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToResults) {
            RoastResultsView(results: results, image: image)
        }
    }

    private func generate() async {
        isGenerating = true
        error = nil
        do {
            let service = makeAIService(config: settingsStore.aiConfig)
            let roasts = try await service.generateRoasts(image: image, config: config)
            results = roasts.map { RoastResult(text: $0, style: config.style, intensity: config.intensityPercent, image: image) }
            navigateToResults = true
        } catch {
            self.error = error.localizedDescription
        }
        isGenerating = false
    }
}

private struct StyleChip: View {
    let style: RoastStyle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(style.emoji)
                    .font(.title2)
                Text(style.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(isSelected ? .black : .white)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.orange : Color.white.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.white.opacity(0.15))
            )
        }
    }
}
