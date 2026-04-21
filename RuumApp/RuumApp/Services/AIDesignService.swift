import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

/// Generates a stylised render of a source room photo.
///
/// The protocol is designed so a real backend (Replicate, OpenAI Images,
/// Stability, etc.) can be dropped in as a replacement. `LocalAIDesignService`
/// ships with the app and does an on-device preview using Core Image, so the
/// app is fully functional without network configuration.
protocol AIDesignGenerating {
    func generate(from image: UIImage,
                  room: Room,
                  style: DesignStyle,
                  mode: DesignMode) async throws -> UIImage
}

final class AIDesignService: ObservableObject, AIDesignGenerating {
    @Published var isGenerating: Bool = false
    @Published var progress: Double = 0

    /// Set this to a concrete remote backend if you wire one up.
    var remote: AIDesignGenerating?

    func generate(from image: UIImage,
                  room: Room,
                  style: DesignStyle,
                  mode: DesignMode) async throws -> UIImage {
        await MainActor.run {
            self.isGenerating = true
            self.progress = 0
        }
        defer {
            Task { @MainActor in
                self.isGenerating = false
                self.progress = 1
            }
        }

        // Animate fake progress so the UI has something to render during generation.
        let progressTask = Task { @MainActor in
            for step in 1...9 {
                try? await Task.sleep(nanoseconds: 180_000_000)
                self.progress = Double(step) / 10.0
            }
        }

        let result: UIImage
        if let remote {
            result = try await remote.generate(from: image, room: room, style: style, mode: mode)
        } else {
            result = try await LocalAIDesignService().generate(from: image, room: room, style: style, mode: mode)
        }

        _ = await progressTask.value
        return result
    }
}

/// Stub implementation: applies a Core Image pipeline keyed to the selected
/// style. Good enough to demo the UX flow end-to-end without a server.
struct LocalAIDesignService: AIDesignGenerating {
    func generate(from image: UIImage,
                  room: Room,
                  style: DesignStyle,
                  mode: DesignMode) async throws -> UIImage {
        try await Task.sleep(nanoseconds: 1_500_000_000)

        guard let ciInput = CIImage(image: image) else { return image }
        let context = CIContext()

        let styled = applyStylePipeline(ciInput, style: style, mode: mode)
        guard let cg = context.createCGImage(styled, from: styled.extent) else { return image }
        return UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
    }

    private func applyStylePipeline(_ input: CIImage, style: DesignStyle, mode: DesignMode) -> CIImage {
        var output = input

        let tint = style.colors.first ?? .white
        let (tr, tg, tb) = components(of: tint)

        let colorMatrix = CIFilter.colorMatrix()
        colorMatrix.inputImage = output
        colorMatrix.rVector = CIVector(x: 0.85 + tr * 0.15, y: 0, z: 0, w: 0)
        colorMatrix.gVector = CIVector(x: 0, y: 0.85 + tg * 0.15, z: 0, w: 0)
        colorMatrix.bVector = CIVector(x: 0, y: 0, z: 0.85 + tb * 0.15, w: 0)
        colorMatrix.aVector = CIVector(x: 0, y: 0, z: 0, w: 1)
        output = colorMatrix.outputImage ?? output

        let controls = CIFilter.colorControls()
        controls.inputImage = output
        controls.saturation = saturation(for: style)
        controls.contrast = contrast(for: style)
        controls.brightness = brightness(for: style)
        output = controls.outputImage ?? output

        if mode == .removeObjects {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = output
            blur.radius = 1.2
            output = blur.outputImage?.cropped(to: input.extent) ?? output
        }

        let vignette = CIFilter.vignette()
        vignette.inputImage = output
        vignette.intensity = 0.4
        vignette.radius = 1.8
        output = vignette.outputImage ?? output

        return output.cropped(to: input.extent)
    }

    private func saturation(for style: DesignStyle) -> Float {
        switch style.id {
        case "minimalist", "japandi", "scandinavian": return 0.75
        case "bohemian", "tropical", "midcentury":    return 1.35
        case "luxury", "artdeco":                     return 1.15
        default:                                      return 1.05
        }
    }

    private func contrast(for style: DesignStyle) -> Float {
        switch style.id {
        case "industrial", "artdeco", "luxury": return 1.15
        case "minimalist", "japandi":           return 0.95
        default:                                return 1.05
        }
    }

    private func brightness(for style: DesignStyle) -> Float {
        switch style.id {
        case "coastal", "scandinavian", "minimalist": return 0.05
        case "industrial", "artdeco":                 return -0.05
        default:                                      return 0
        }
    }

    private func components(of color: Color) -> (Double, Double, Double) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
    }
}
