import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            WaterEjectView()
                .tabItem { Label("Water Eject", systemImage: "drop.fill") }

            DBMeterView()
                .tabItem { Label("DB Meter", systemImage: "waveform") }

            ToneGeneratorView()
                .tabItem { Label("Tone", systemImage: "music.note") }

            StereoTestView()
                .tabItem { Label("Stereo", systemImage: "speaker.2.fill") }
        }
        .tint(.blue)
    }
}
