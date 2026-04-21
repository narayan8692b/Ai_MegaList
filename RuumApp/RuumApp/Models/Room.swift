import Foundation

struct Room: Identifiable, Hashable, Codable {
    let id: String
    let name: String
    let sfSymbol: String

    static let all: [Room] = [
        Room(id: "living",   name: "Living Room",   sfSymbol: "sofa"),
        Room(id: "bedroom",  name: "Bedroom",       sfSymbol: "bed.double"),
        Room(id: "kitchen",  name: "Kitchen",       sfSymbol: "fork.knife"),
        Room(id: "bathroom", name: "Bathroom",      sfSymbol: "shower"),
        Room(id: "dining",   name: "Dining Room",   sfSymbol: "table.furniture"),
        Room(id: "office",   name: "Home Office",   sfSymbol: "desktopcomputer"),
        Room(id: "study",    name: "Study Room",    sfSymbol: "books.vertical"),
        Room(id: "gaming",   name: "Gaming Room",   sfSymbol: "gamecontroller"),
        Room(id: "kids",     name: "Kids Room",     sfSymbol: "teddybear"),
        Room(id: "garden",   name: "Garden",        sfSymbol: "leaf"),
        Room(id: "backyard", name: "Backyard",      sfSymbol: "tree"),
        Room(id: "exterior", name: "Exterior",      sfSymbol: "house")
    ]
}
