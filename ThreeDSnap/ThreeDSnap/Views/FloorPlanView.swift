import SwiftUI

struct FloorPlanView: View {
    let scan: Scan

    var body: some View {
        GeometryReader { geo in
            let layout = Layout(scan: scan, canvas: geo.size)
            ZStack {
                Color.white
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                Canvas { ctx, size in
                    drawDimensions(ctx: ctx, layout: layout)
                    drawRooms(ctx: ctx, layout: layout)
                }

                VStack {
                    Spacer()
                    totalAreaPill
                        .padding(.bottom, 24)
                }
            }
            .padding(16)
        }
    }

    private var totalAreaPill: some View {
        Text("Total area: \(MeasurementFormatter.formatArea(scan.totalAreaSquareMeters, unit: scan.lengthUnit))")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.blue, in: Capsule())
    }

    private func drawRooms(ctx: GraphicsContext, layout: Layout) {
        for room in scan.rooms {
            let rect = layout.rect(for: room)

            // Wall fill
            ctx.fill(Path(roundedRect: rect, cornerRadius: 0),
                     with: .color(.black.opacity(0.92)))

            // Inset interior
            let inset = rect.insetBy(dx: 6, dy: 6)
            ctx.fill(Path(roundedRect: inset, cornerRadius: 0),
                     with: .color(.white))

            // Area label
            let area = MeasurementFormatter.formatArea(room.areaSquareMeters, unit: scan.lengthUnit)
            let textPoint = CGPoint(x: inset.midX, y: inset.midY)
            let raw = textSize(area, font: .systemFont(ofSize: 11, weight: .semibold))
            let pillSize = CGSize(width: raw.width + 12, height: raw.height + 6)
            let pillRect = CGRect(
                x: textPoint.x - pillSize.width / 2,
                y: textPoint.y - pillSize.height / 2,
                width: pillSize.width,
                height: pillSize.height
            )
            ctx.fill(
                Path(roundedRect: pillRect, cornerRadius: 6),
                with: .color(Color(red: 0.2, green: 0.22, blue: 0.27))
            )
            ctx.draw(
                Text(area).font(.system(size: 11, weight: .semibold)).foregroundStyle(.white),
                at: textPoint
            )
        }
    }

    private func drawDimensions(ctx: GraphicsContext, layout: Layout) {
        let bounding = layout.bounding
        let stroke = StrokeStyle(lineWidth: 1.2)
        let blue = Color.blue

        // Top horizontal
        let topY = bounding.minY - 26
        ctx.stroke(
            Path { p in
                p.move(to: CGPoint(x: bounding.minX, y: topY))
                p.addLine(to: CGPoint(x: bounding.maxX, y: topY))
            },
            with: .color(blue),
            style: stroke
        )
        drawArrow(ctx: ctx, at: CGPoint(x: bounding.minX, y: topY), direction: .left, color: blue)
        drawArrow(ctx: ctx, at: CGPoint(x: bounding.maxX, y: topY), direction: .right, color: blue)
        let widthLabel = MeasurementFormatter.formatLength(scan.boundingSizeMeters.width, unit: scan.lengthUnit)
        ctx.draw(
            Text(widthLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(blue),
            at: CGPoint(x: bounding.midX, y: topY - 10)
        )

        // Bottom horizontal
        let bottomY = bounding.maxY + 26
        ctx.stroke(
            Path { p in
                p.move(to: CGPoint(x: bounding.minX, y: bottomY))
                p.addLine(to: CGPoint(x: bounding.maxX, y: bottomY))
            },
            with: .color(blue),
            style: stroke
        )
        drawArrow(ctx: ctx, at: CGPoint(x: bounding.minX, y: bottomY), direction: .left, color: blue)
        drawArrow(ctx: ctx, at: CGPoint(x: bounding.maxX, y: bottomY), direction: .right, color: blue)
        ctx.draw(
            Text(widthLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(blue),
            at: CGPoint(x: bounding.midX, y: bottomY + 10)
        )

        // Left vertical
        let leftX = bounding.minX - 22
        ctx.stroke(
            Path { p in
                p.move(to: CGPoint(x: leftX, y: bounding.minY))
                p.addLine(to: CGPoint(x: leftX, y: bounding.maxY))
            },
            with: .color(blue),
            style: stroke
        )
        drawArrow(ctx: ctx, at: CGPoint(x: leftX, y: bounding.minY), direction: .up, color: blue)
        drawArrow(ctx: ctx, at: CGPoint(x: leftX, y: bounding.maxY), direction: .down, color: blue)
        let heightLabel = MeasurementFormatter.formatLength(scan.boundingSizeMeters.height, unit: scan.lengthUnit)
        ctx.draw(
            Text(heightLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(blue),
            at: CGPoint(x: leftX - 14, y: bounding.midY)
        )

        // Right vertical
        let rightX = bounding.maxX + 22
        ctx.stroke(
            Path { p in
                p.move(to: CGPoint(x: rightX, y: bounding.minY))
                p.addLine(to: CGPoint(x: rightX, y: bounding.maxY))
            },
            with: .color(blue),
            style: stroke
        )
        drawArrow(ctx: ctx, at: CGPoint(x: rightX, y: bounding.minY), direction: .up, color: blue)
        drawArrow(ctx: ctx, at: CGPoint(x: rightX, y: bounding.maxY), direction: .down, color: blue)
        ctx.draw(
            Text(heightLabel)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(blue),
            at: CGPoint(x: rightX + 14, y: bounding.midY)
        )
    }

    private enum ArrowDirection { case left, right, up, down }

    private func drawArrow(ctx: GraphicsContext,
                           at point: CGPoint,
                           direction: ArrowDirection,
                           color: Color) {
        var p = Path()
        let s: CGFloat = 5
        switch direction {
        case .left:
            p.move(to: CGPoint(x: point.x + s, y: point.y - s))
            p.addLine(to: point)
            p.addLine(to: CGPoint(x: point.x + s, y: point.y + s))
            p.closeSubpath()
        case .right:
            p.move(to: CGPoint(x: point.x - s, y: point.y - s))
            p.addLine(to: point)
            p.addLine(to: CGPoint(x: point.x - s, y: point.y + s))
            p.closeSubpath()
        case .up:
            p.move(to: CGPoint(x: point.x - s, y: point.y + s))
            p.addLine(to: point)
            p.addLine(to: CGPoint(x: point.x + s, y: point.y + s))
            p.closeSubpath()
        case .down:
            p.move(to: CGPoint(x: point.x - s, y: point.y - s))
            p.addLine(to: point)
            p.addLine(to: CGPoint(x: point.x + s, y: point.y - s))
            p.closeSubpath()
        }
        ctx.fill(p, with: .color(color))
    }

    private func textSize(_ text: String, font: UIFont) -> CGSize {
        let attrs: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attrs)
    }

    private struct Layout {
        let scan: Scan
        let canvas: CGSize
        let bounding: CGRect
        let scale: CGFloat
        let xOffset: CGFloat
        let yOffset: CGFloat

        init(scan: Scan, canvas: CGSize) {
            self.scan = scan
            self.canvas = canvas

            let size = scan.boundingSizeMeters
            let padding: CGFloat = 70
            let availableW = canvas.width - padding * 2
            let availableH = canvas.height - padding * 2 - 40
            let scale = min(
                availableW / max(size.width, 0.1),
                availableH / max(size.height, 0.1)
            )
            self.scale = scale

            let drawnW = size.width * scale
            let drawnH = size.height * scale
            let offsetX = (canvas.width - drawnW) / 2
            let offsetY = (canvas.height - drawnH) / 2 - 20
            self.xOffset = offsetX
            self.yOffset = offsetY

            self.bounding = CGRect(x: offsetX, y: offsetY, width: drawnW, height: drawnH)
        }

        func rect(for room: Room) -> CGRect {
            // Translate room origin so the bounding box starts at (0,0).
            var minX = Double.greatestFiniteMagnitude
            var minY = Double.greatestFiniteMagnitude
            for r in scan.rooms {
                minX = min(minX, r.origin.x)
                minY = min(minY, r.origin.y)
            }
            let dx = (room.origin.x - minX) * scale
            let dy = (room.origin.y - minY) * scale
            return CGRect(
                x: xOffset + dx,
                y: yOffset + dy,
                width: room.size.width * scale,
                height: room.size.height * scale
            )
        }
    }
}

#Preview {
    FloorPlanView(scan: ScanStore.preview.scans.first!)
        .background(Color.black)
}
