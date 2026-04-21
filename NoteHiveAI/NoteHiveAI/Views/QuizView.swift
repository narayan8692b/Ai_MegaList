import SwiftUI

struct QuizView: View {
    let questions: [QuizQuestion]

    @State private var currentIndex: Int = 0
    @State private var selectedOption: Int? = nil
    @State private var correctCount: Int = 0
    @State private var answered: Bool = false
    @State private var finished: Bool = false

    var body: some View {
        if questions.isEmpty {
            EmptyTabState(
                icon: "questionmark.circle",
                title: "No quiz yet",
                subtitle: "Tap the refresh icon to generate quiz questions from your transcription."
            )
        } else if finished {
            finishView
        } else {
            let question = questions[currentIndex]
            VStack(alignment: .leading, spacing: 16) {
                Text("Question \(currentIndex + 1) of \(questions.count)")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(Theme.textSecondary)

                Text(question.question)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(Theme.textPrimary)

                VStack(spacing: 10) {
                    ForEach(question.options.indices, id: \.self) { idx in
                        optionRow(
                            text: question.options[idx],
                            index: idx,
                            correctIndex: question.correctIndex
                        )
                    }
                }

                Button {
                    advance()
                } label: {
                    HStack {
                        Text(currentIndex == questions.count - 1 ? "Finish" : "Next Question")
                            .font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 18)
                    .frame(maxWidth: .infinity)
                    .background(answered ? Theme.accent : Theme.accent.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!answered)
                .padding(.top, 6)
            }
            .padding(14)
            .cardBackground()
        }
    }

    private func optionRow(text: String, index: Int, correctIndex: Int) -> some View {
        let isSelected = selectedOption == index
        let isCorrect = answered && index == correctIndex
        let isWrong = answered && isSelected && index != correctIndex

        let fill: Color = {
            if isCorrect { return Color.green.opacity(0.75) }
            if isWrong { return Color.red.opacity(0.7) }
            if isSelected { return Theme.accent.opacity(0.3) }
            return Theme.pillInactive
        }()

        return Button {
            guard !answered else { return }
            selectedOption = index
            answered = true
            if index == correctIndex { correctCount += 1 }
        } label: {
            HStack {
                Text(text)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Spacer()
                if isCorrect {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                } else if isWrong {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Theme.pillStroke, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var finishView: some View {
        VStack(spacing: 14) {
            Image(systemName: "rosette")
                .font(.system(size: 56))
                .foregroundColor(Theme.accent)
            Text("Quiz Complete!")
                .font(.title3.weight(.semibold))
                .foregroundColor(Theme.textPrimary)
            Text("Score: \(correctCount) / \(questions.count)")
                .font(.headline)
                .foregroundColor(Theme.textSecondary)
            Button("Retake Quiz") {
                correctCount = 0
                currentIndex = 0
                selectedOption = nil
                answered = false
                finished = false
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
            .background(Theme.accent)
            .foregroundColor(.white)
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding()
        .cardBackground()
    }

    private func advance() {
        if currentIndex < questions.count - 1 {
            currentIndex += 1
            selectedOption = nil
            answered = false
        } else {
            finished = true
        }
    }
}
