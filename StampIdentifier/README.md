# Collectibles Identifier (iOS / SwiftUI)

A SwiftUI iOS app that scans, identifies, values, and catalogs **four
categories** of collectibles — postage stamps, antiques, jewelry, and coins —
modeled on the App Store listings for *Stamp Identifier: Scan Value*,
*Antique Identifier: Appraiser+*, *Jewelry Identifier: JewelryID*, and
*Coin Identifier - Scan Value*.

## Features

### Four modes, one app

A horizontal chip picker (Stamps / Antiques / Jewelry / Coins) retints the
whole surface and switches the data source. Selection persists in
`@AppStorage` so the mode is remembered across relaunch. Coins use a
dark theme; the others use cream themes.

### Scan & Identify

- Camera capture and photo library picker.
- Corner-framed scanner viewfinder (orange / gold / jewelry-gold / coin-gold).
- Progress overlay during identification.
- Language chip with a 15-language picker — mirrors the App Store
  "Ask in Your Language" screenshots shared across all four listings.

### Stamp details

- Estimated dollar value, AI confidence pill, rarity badge, value range.
- Catalog numbers, country, year, denomination.
- Collapsible Description, Physical Analysis, Historical Context, Value
  Analysis, Collector Info.

### Antique details

- `BRONZE VASE 1880` headline, gold value-range banner, AI conf. pill.
- Metadata: Category, Subcategory, Style, Year Made, Origin, Maker.
- Nine collapsible sections: Item Identification, Dating & Age,
  Origin & Provenance, Materials & Construction, Physical Characteristics,
  Condition Assessment, Valuation, Rarity & Significance,
  Authenticity & Authentication.

### Jewelry details

- Estimated-value headline block matching the App Store listing
  (ESTIMATED VALUE $1,650 style).
- Summary card.
- Materials breakdown (metal + gemstones) with karat, weight, and 4-C
  grading lines.
- Hallmarks chip row (750, 585, IGI, etc.).
- **Value justification** — monospaced calculation breakdown
  (metal spot × purity × weight, craftsmanship multiplier, condition,
  market demand, eBay anchor), mirroring the "Buy Smarter, Sell Higher"
  screenshot.
- Comparable-sales notes.
- **Ask AI** chat sheet (opener auto-sends, follow-up chip suggestions).
- **Check eBay** sheet — paste listing title + price, returns "Fair Price"
  or "Overpriced" with ±% below/above-market and confidence.

### Coin details (Identification Details)

- `GOLD COIN 1876` headline with AI Conf. pill.
- Value-range banner (`$2,000 - $4,000`).
- Metadata rows: Type, Denomination, Materials, Year, Country, Mint Mark.
- Eight collapsible sections: Historical Context, Technical Details,
  Condition & Grading, Market & Investment, Foreign coin Details,
  Educational Content, Personalization, Social & Sharing.

### Collection / Identification History

- Each mode persists independently (UserDefaults-backed store).
- Jewelry uses a large total-value pill (`$8,684`) mirroring the
  "Watch Your Value Grow" screenshot; other modes show dual count + value
  tiles.
- Search by name, country/type, catalog number, material, style, etc.
- Long-press to remove.

### Learn

- Four curated topic sets (6-8 per mode).
- Stamps: catalog numbers, grading, watermarks, storage, authentication.
- Antiques: dating, provenance, construction, condition, authenticity,
  valuation.
- Jewelry: karats, gemstones, hallmarks, condition, market channels,
  insurance.
- Coins: historical context, technical, condition, market, foreign
  attribution, authentication.

## Project layout

```
StampIdentifier/
├── project.yml                           # XcodeGen project spec
├── README.md
└── StampIdentifier/
    ├── StampIdentifierApp.swift          # Injects all four stores
    ├── Theme.swift                       # Brand colors x4
    ├── Info.plist
    ├── Assets.xcassets/                  # AppIcon, AccentColor,
    │                                     #   BrandOrange, BrandCream,
    │                                     #   AntiqueGold, AntiqueCream,
    │                                     #   JewelryGold, JewelryCream,
    │                                     #   CoinGold, CoinCream
    ├── Models/
    │   ├── CollectibleMode.swift         # .stamp / .antique / .jewelry / .coin
    │   ├── Stamp.swift
    │   ├── Antique.swift
    │   ├── Jewelry.swift                 # metals + gems + hallmarks + chat model
    │   └── Coin.swift
    ├── Services/
    │   ├── CurrencyFormatter.swift
    │   ├── StampStore.swift
    │   ├── AntiqueStore.swift
    │   ├── JewelryStore.swift
    │   ├── CoinStore.swift
    │   ├── StampIdentificationService.swift
    │   ├── AntiqueIdentificationService.swift
    │   ├── JewelryIdentificationService.swift   # + eBay checker + AI advisor
    │   └── CoinIdentificationService.swift
    └── Views/
        ├── RootTabView.swift             # Scan / Collection / Learn tabs
        ├── ScanView.swift                # Mode + language + camera / library
        ├── CameraPicker.swift
        ├── CollectionView.swift          # Mode-aware grid + totals + search
        ├── LearnView.swift               # 4 topic sets
        ├── LanguagePickerView.swift      # 15-language selector
        ├── StampDetailView.swift
        ├── AntiqueDetailView.swift
        ├── JewelryDetailView.swift       # Estimated value, materials, hallmarks,
        │                                 # value justification, Ask AI + Check eBay
        ├── JewelryChatView.swift         # Conversation with follow-ups
        ├── EBayCheckerView.swift         # Fair Price / confidence
        ├── CoinDetailView.swift          # Identification Details sections
        └── Components/
            ├── ModeChipPicker.swift      # Horizontal mode chips
            ├── RarityBadge.swift
            ├── StampCardView.swift
            ├── AntiqueCardView.swift
            ├── JewelryCardView.swift
            └── CoinCardView.swift
```

## Building

### Option A — XcodeGen (recommended)

```bash
brew install xcodegen            # one-time
cd StampIdentifier
xcodegen generate                # creates StampIdentifier.xcodeproj
open StampIdentifier.xcodeproj
```

### Option B — fresh Xcode project

1. Open Xcode → **File › New › Project › iOS › App**, name
   `StampIdentifier`, choose **SwiftUI** / **Swift** / iOS 17+.
2. Delete the stub `ContentView.swift` / `*App.swift` Xcode generated.
3. Drag the repo's `StampIdentifier/` source folder into the project
   navigator ("Copy items if needed", "Create groups").
4. Ensure the asset catalog and `Info.plist` are included in the target.

## Swapping the mock identifiers for real ones

Four protocols live in `Services/`:

- `StampIdentifying`
- `AntiqueIdentifying`
- `JewelryIdentifying` (+ `EBayPriceChecking` + `JewelryAdvising`)
- `CoinIdentifying`

Mock implementations return plausible seed data after a short delay.
Replace any one with a Vision / Core ML / Anthropic Claude vision backend
without touching the UI.

## Requirements

- Xcode 15+
- iOS 17+ (uses `NavigationStack`, `PhotosPicker`, `safeAreaInset`,
  `navigationDestination(item:)`, `toolbarColorScheme`)

## License

MIT
