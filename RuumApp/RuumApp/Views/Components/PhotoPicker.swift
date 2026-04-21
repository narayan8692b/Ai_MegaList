import SwiftUI
import PhotosUI

struct PhotoPicker: View {
    @Binding var image: UIImage?
    @State private var item: PhotosPickerItem?

    var body: some View {
        PhotosPicker(selection: $item, matching: .images) {
            label
        }
        .onChange(of: item) { newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let ui = UIImage(data: data) {
                    await MainActor.run { self.image = ui }
                }
            }
        }
    }

    private var label: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous)
                .fill(Color.ruumCard)
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: Layout.cardRadius, style: .continuous))
            } else {
                VStack(spacing: 10) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 42, weight: .light))
                        .foregroundColor(.ruumTeal)
                    Text("Tap to add a room photo")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("JPG or PNG · clear, well-lit")
                        .font(.caption)
                        .foregroundColor(.ruumMuted)
                }
                .padding()
            }
        }
        .frame(height: 260)
        .overlay(alignment: .topTrailing) {
            if image != nil {
                Button {
                    image = nil
                    item = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.white, .black.opacity(0.55))
                        .padding(8)
                }
            }
        }
    }
}
