import SwiftUI

struct DBMeterView: View {

    @StateObject private var meter = DBMeterEngine()

    private var badgeColor: Color {
        switch meter.badge {
        case "Safe":     return .green
        case "Moderate": return .yellow
        case "Loud":     return .orange
        default:         return .red
        }
    }

    private var gaugePercent: Double { min(1, Double(meter.currentLevel) / 120) }
    private var peakPercent:  Double { min(1, Double(meter.peakLevel)    / 120) }

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    dbDisplay
                    gaugeCard
                    buttonRow
                    historyCard
                    referenceCard
                    Spacer(minLength: 24)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("DB Meter")
        }
        .onDisappear { meter.stop() }
    }

    // MARK: - Sub-views

    private var dbDisplay: some View {
        VStack(spacing: 8) {
            Text(meter.badge)
                .font(.caption.weight(.bold))
                .foregroundColor(badgeColor)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(badgeColor.opacity(0.15))
                .cornerRadius(20)

            HStack(alignment: .bottom, spacing: 4) {
                Text(String(format: "%.1f", meter.currentLevel))
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .animation(.none, value: meter.currentLevel)
                Text("dB")
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12)
            }

            Text("Peak: \(String(format: "%.1f", meter.peakLevel)) dB")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 8)
    }

    private var gaugeCard: some View {
        VStack(spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading, endPoint: .trailing))
                        .opacity(0.2)
                        .frame(height: 18)

                    // Fill
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(
                            colors: [.green, .yellow, .orange, .red],
                            startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * CGFloat(gaugePercent), height: 18)
                        .animation(.linear(duration: 0.08), value: gaugePercent)

                    // Peak marker
                    if meter.peakLevel > 0 {
                        Capsule()
                            .fill(Color.white)
                            .frame(width: 3, height: 24)
                            .offset(x: geo.size.width * CGFloat(peakPercent) - 1.5, y: -3)
                    }
                }
            }
            .frame(height: 18)

            HStack {
                ForEach(["0", "40", "60", "80", "100+"], id: \.self) { label in
                    Text(label).font(.caption2).foregroundColor(.secondary)
                    if label != "100+" { Spacer() }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var buttonRow: some View {
        HStack(spacing: 12) {
            Button(action: toggleMeter) {
                HStack(spacing: 8) {
                    Image(systemName: meter.isRecording ? "stop.fill" : "mic.fill")
                    Text(meter.isRecording ? "Stop" : "Start Recording")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(meter.isRecording ? Color.red : Color.blue)
                .cornerRadius(14)
            }

            Button(action: meter.resetPeak) {
                Text("Reset Peak")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(14)
            }
        }
        .padding(.horizontal)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Sound Level History")
                .font(.subheadline.weight(.semibold))

            if meter.history.isEmpty {
                Text("Start recording to see history")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 28)
            } else {
                DBHistoryChart(history: meter.history)
                    .frame(height: 80)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    private var referenceCard: some View {
        let refs: [(String, String, Color)] = [
            ("Whisper",              "~30 dB",  .green),
            ("Normal Conversation",  "~60 dB",  .blue),
            ("Loud Music",           "~90 dB",  .orange),
            ("Hearing Damage Risk",  "~120 dB", .red),
        ]
        return VStack(alignment: .leading, spacing: 12) {
            Text("Reference Levels")
                .font(.subheadline.weight(.semibold))
            ForEach(refs, id: \.0) { name, level, color in
                HStack {
                    Circle().fill(color).frame(width: 10, height: 10)
                    Text(name).font(.caption)
                    Spacer()
                    Text(level).font(.caption).foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
        .padding(.horizontal)
    }

    // MARK: - Actions

    private func toggleMeter() {
        meter.isRecording ? meter.stop() : meter.start()
    }
}

// MARK: - History Chart

struct DBHistoryChart: View {
    let history: [Float]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let count = history.count
            guard count > 1 else { return AnyView(EmptyView()) }
            let step = w / CGFloat(count - 1)

            func point(at i: Int) -> CGPoint {
                CGPoint(
                    x: CGFloat(i) * step,
                    y: h - CGFloat(history[i]) / 120 * h
                )
            }

            return AnyView(ZStack {
                // Fill
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h))
                    for i in 0..<count { p.addLine(to: point(at: i)) }
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.closeSubpath()
                }
                .fill(Color.blue.opacity(0.12))

                // Line
                Path { p in
                    p.move(to: point(at: 0))
                    for i in 1..<count { p.addLine(to: point(at: i)) }
                }
                .stroke(Color.blue, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            })
        }
    }
}
