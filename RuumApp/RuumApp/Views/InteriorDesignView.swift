import SwiftUI

struct InteriorDesignView: View {
    let mode: DesignMode
    var preselectedStyle: DesignStyle? = nil

    @EnvironmentObject private var designService: AIDesignService
    @EnvironmentObject private var storage: DesignStorage

    @State private var sourceImage: UIImage?
    @State private var selectedRoom: Room = Room.all[0]
    @State private var selectedStyle: DesignStyle = DesignStyle.all[0]
    @State private var generated: Design?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PhotoPicker(image: $sourceImage)

                selectRoom
                selectStyle

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }

                Button {
                    Task { await generate() }
                } label: {
                    HStack(spacing: 10) {
                        if designService.isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                        }
                        Text(designService.isGenerating ? "Generating… \(Int(designService.progress * 100))%"
                                                        : "Generate Design")
                    }
                }
                .disabled(sourceImage == nil || designService.isGenerating)
                .buttonStyle(PrimaryButtonStyle(isEnabled: sourceImage != nil && !designService.isGenerating))
            }
            .padding(Layout.padding)
        }
        .background(Color.ruumBackground.ignoresSafeArea())
        .navigationTitle(mode.title + " Design")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $generated) { design in
            DesignResultView(design: design)
        }
        .onAppear {
            if let preselectedStyle { selectedStyle = preselectedStyle }
        }
    }

    private var selectRoom: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Select Room")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Room.all) { room in
                        RoomChip(room: room, isSelected: selectedRoom == room) {
                            selectedRoom = room
                        }
                    }
                }
            }
        }
    }

    private var selectStyle: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Select Style")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(DesignStyle.all) { style in
                        StyleCard(style: style, isSelected: selectedStyle == style) {
                            selectedStyle = style
                        }
                        .frame(width: 140)
                    }
                }
            }
        }
    }

    private func generate() async {
        guard let sourceImage else { return }
        errorMessage = nil
        do {
            let result = try await designService.generate(
                from: sourceImage,
                room: selectedRoom,
                style: selectedStyle,
                mode: mode
            )
            let design = storage.save(
                original: sourceImage,
                generated: result,
                room: selectedRoom,
                style: selectedStyle,
                mode: mode
            )
            generated = design
        } catch {
            errorMessage = "Something went wrong: \(error.localizedDescription)"
        }
    }
}
