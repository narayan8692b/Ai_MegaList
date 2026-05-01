import SwiftUI

struct MeasureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var unit: LengthUnit = .feet

    #if canImport(ARKit) && canImport(SceneKit) && !targetEnvironment(simulator)
    @StateObject private var coordinator = MeasureCoordinator()
    #endif

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            #if canImport(ARKit) && canImport(SceneKit) && !targetEnvironment(simulator)
            MeasureARViewRepresentable(coordinator: coordinator)
                .ignoresSafeArea()
            #else
            VStack(spacing: 12) {
                Image(systemName: "ruler.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.orange)
                Text("AR Measure")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("AR measurement is unavailable on this device or simulator.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.horizontal, 32)
            }
            #endif

            VStack {
                topBar
                Spacer()
                bottomReadout
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
    }

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            Picker("Unit", selection: $unit) {
                Text("ft").tag(LengthUnit.feet)
                Text("m").tag(LengthUnit.meters)
            }
            .pickerStyle(.segmented)
            .frame(width: 120)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.ultraThinMaterial, in: Capsule())
            Spacer()
            Button {
                #if canImport(ARKit) && canImport(SceneKit) && !targetEnvironment(simulator)
                coordinator.reset()
                #endif
            } label: {
                Image(systemName: "arrow.counterclockwise")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
            }
        }
    }

    private var bottomReadout: some View {
        VStack(spacing: 10) {
            #if canImport(ARKit) && canImport(SceneKit) && !targetEnvironment(simulator)
            if let d = coordinator.distanceMeters {
                Text(MeasurementFormatter.formatLength(d, unit: unit))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            } else {
                Text(coordinator.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            #else
            Text("Preview mode")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))
            #endif
        }
    }
}

#Preview {
    MeasureView()
}
