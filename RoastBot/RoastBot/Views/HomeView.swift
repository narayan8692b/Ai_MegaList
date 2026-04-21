import SwiftUI
import PhotosUI

struct HomeView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCustomize = false
    @State private var showCamera = false
    @State private var showNoKeyAlert = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // Logo + title
                VStack(spacing: 12) {
                    Text("🔥")
                        .font(.system(size: 80))
                    Text("Roast Bot")
                        .font(.system(size: 42, weight: .black))
                        .foregroundColor(.white)
                    Text("AI Roast Generator")
                        .font(.title3)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Photo preview
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 260, height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.orange, lineWidth: 3)
                        )
                        .shadow(color: .orange.opacity(0.4), radius: 20)
                }

                Spacer()

                // CTA buttons
                VStack(spacing: 14) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Choose Photo", systemImage: "photo.on.rectangle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label("Take Photo", systemImage: "camera.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2))
                            )
                    }

                    if selectedImage != nil {
                        Button {
                            guard settingsStore.aiConfig.isValid else {
                                showNoKeyAlert = true
                                return
                            }
                            showCustomize = true
                        } label: {
                            Label("Roast This!", systemImage: "flame.fill")
                                .font(.title3.bold())
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(colors: [.red, .orange], startPoint: .leading, endPoint: .trailing)
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: .orange.opacity(0.5), radius: 10)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 28)
                .animation(.spring(response: 0.35), value: selectedImage != nil)

                Spacer(minLength: 20)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selectedPhoto) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let img = UIImage(data: data) {
                    selectedImage = img
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
        }
        .navigationDestination(isPresented: $showCustomize) {
            if let img = selectedImage {
                CustomizeRoastView(image: img)
                    .environmentObject(settingsStore)
            }
        }
        .alert("No API Key", isPresented: $showNoKeyAlert) {
            Button("OK") {}
        } message: {
            Text("Please add your AI provider API key in Settings (gear icon) before generating roasts.")
        }
    }
}
