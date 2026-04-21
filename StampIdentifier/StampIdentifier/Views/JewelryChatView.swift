import SwiftUI

struct JewelryChatView: View {
    let piece: Jewelry
    @Environment(\.dismiss) private var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var draft: String = ""
    @State private var isReplying = false

    private let advisor: JewelryAdvising = MockJewelryAdvisor()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                chatHeader
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            if isReplying {
                                HStack(spacing: 6) {
                                    ProgressView()
                                    Text("Thinking…")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical, 12)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                if messages.last?.role == .assistant {
                    suggestions
                }

                inputBar
            }
            .background(Color.jewelryCream.ignoresSafeArea())
            .navigationTitle("Ask AI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                if messages.isEmpty {
                    await sendInitial()
                }
            }
        }
    }

    // MARK: Subviews

    private var chatHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CHATTING ABOUT")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(Color.jewelryGold)
                VStack(alignment: .leading, spacing: 2) {
                    Text(piece.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandInk)
                        .lineLimit(2)
                    Text("\(piece.type.rawValue) · \(piece.estimatedValueDisplay)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Color.white
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var suggestions: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(advisor.followUpSuggestions(for: piece), id: \.self) { suggestion in
                    Button {
                        Task { await send(prompt: suggestion) }
                    } label: {
                        Text(suggestion)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                Capsule().fill(Color.jewelryGold.opacity(0.12))
                            )
                            .foregroundStyle(Color.jewelryGold)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask about this piece…", text: $draft)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.send)
                .onSubmit { Task { await sendDraft() } }

            Button {
                Task { await sendDraft() }
            } label: {
                Image(systemName: "paperplane.fill")
                    .padding(10)
                    .background(Circle().fill(Color.jewelryGold))
                    .foregroundStyle(.white)
            }
            .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isReplying)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    // MARK: Logic

    private func sendInitial() async {
        let opener = "I would like to know more about '\(piece.name)'"
        await send(prompt: opener)
    }

    private func sendDraft() async {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        await send(prompt: text)
    }

    private func send(prompt: String) async {
        messages.append(ChatMessage(role: .user, text: prompt))
        isReplying = true
        defer { isReplying = false }
        do {
            let reply = try await advisor.reply(to: prompt, about: piece, previous: messages)
            messages.append(ChatMessage(role: .assistant, text: reply))
        } catch {
            messages.append(ChatMessage(role: .assistant,
                                        text: "Sorry, I couldn't answer that right now."))
        }
    }
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 40) }
            Text(message.text)
                .font(.subheadline)
                .foregroundStyle(message.role == .user ? .white : Color.brandInk)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(message.role == .user
                              ? Color.jewelryGold
                              : Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                )
            if message.role == .assistant { Spacer(minLength: 40) }
        }
        .padding(.horizontal)
    }
}

#Preview {
    JewelryChatView(piece: .sampleBaroquePearl)
}
