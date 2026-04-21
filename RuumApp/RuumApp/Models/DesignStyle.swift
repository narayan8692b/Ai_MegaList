import SwiftUI

struct DesignStyle: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let tagline: String
    let palette: [String]

    var colors: [Color] { palette.map { Color(hex: $0) } }

    static let all: [DesignStyle] = [
        .init(id: "modern",      name: "Modern",      tagline: "Clean lines, neutral tones",      palette: ["#D9D0C1", "#8C8279", "#3A3733"]),
        .init(id: "minimalist",  name: "Minimalist",  tagline: "Less, but better",                palette: ["#F5F3EE", "#C8C2B6", "#2E2D2B"]),
        .init(id: "industrial",  name: "Industrial",  tagline: "Raw metals, exposed brick",       palette: ["#4E4A46", "#86776B", "#1C1A18"]),
        .init(id: "scandinavian",name: "Scandinavian",tagline: "Light wood, airy whites",         palette: ["#EFE9DF", "#CBB79B", "#6E5A44"]),
        .init(id: "bohemian",    name: "Bohemian",    tagline: "Eclectic textures & warmth",      palette: ["#D98E4A", "#A04A2C", "#EFD9B4"]),
        .init(id: "coastal",     name: "Coastal",     tagline: "Breezy blues and sand",           palette: ["#DCE9F2", "#7FB3C8", "#2E4E5F"]),
        .init(id: "midcentury",  name: "Mid-Century", tagline: "Retro silhouettes, bold hues",    palette: ["#D46A3A", "#E9C37D", "#2A3340"]),
        .init(id: "farmhouse",   name: "Farmhouse",   tagline: "Rustic, cozy, classic",           palette: ["#EADFCE", "#A58868", "#3D2F24"]),
        .init(id: "japandi",     name: "Japandi",     tagline: "Japanese meets Scandi",           palette: ["#E8E2D8", "#8C7A65", "#2B241D"]),
        .init(id: "artdeco",     name: "Art Deco",    tagline: "Glam, geometric, gold",           palette: ["#1D1D27", "#C9A15A", "#E5DFD3"]),
        .init(id: "tropical",    name: "Tropical",    tagline: "Lush greens, rattan",             palette: ["#BBD49C", "#3F6B44", "#F3ECD8"]),
        .init(id: "luxury",      name: "Luxury",      tagline: "Velvet, marble, brass",           palette: ["#2A2636", "#B68F5A", "#EDE5D7"])
    ]
}

extension Color {
    init(hex: String) {
        var str = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        if str.hasPrefix("#") { str.removeFirst() }
        var value: UInt64 = 0
        Scanner(string: str).scanHexInt64(&value)
        let r = Double((value & 0xFF0000) >> 16) / 255.0
        let g = Double((value & 0x00FF00) >> 8) / 255.0
        let b = Double(value & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
