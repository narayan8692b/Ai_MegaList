import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var scanStore: ScanStore
    @State private var showingRoomScanner = false
    @State private var showingMeasure = false
    @State private var showingUnsupportedAlert = false
    @State private var unsupportedMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    heroBanner
                    actionGrid
                    recentSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .background(
                LinearGradient(
                    colors: [Color.black, Color(red: 0.05, green: 0.05, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle("3D Snap")
            .navigationBarTitleDisplayMode(.large)
        }
        .fullScreenCover(isPresented: $showingRoomScanner) {
            RoomScannerView()
        }
        .fullScreenCover(isPresented: $showingMeasure) {
            MeasureView()
        }
        .alert("Not Supported", isPresented: $showingUnsupportedAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(unsupportedMessage)
        }
    }

    private var heroBanner: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cube.transparent.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                Spacer()
            }

            Text("Say goodbye to measuring tape")
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text("Capture rooms in 3D, measure any distance, and save floor plans — all from your iPhone.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.75))

            Button {
                startRoomScan()
            } label: {
                HStack {
                    Image(systemName: "viewfinder")
                    Text("Start New Room Scan")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .padding(.vertical, 14)
                .padding(.horizontal, 18)
                .background(
                    LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var actionGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tools")
                .font(.headline)
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                ToolTile(
                    title: "Room Scan",
                    subtitle: "Walk around to capture the entire room",
                    icon: "house.fill",
                    gradient: [.blue, .cyan]
                ) {
                    startRoomScan()
                }
                ToolTile(
                    title: "Measure",
                    subtitle: "Tap two points to measure distance",
                    icon: "ruler.fill",
                    gradient: [.orange, .pink]
                ) {
                    startMeasure()
                }
                ToolTile(
                    title: "Library",
                    subtitle: "Saved scans and exports",
                    icon: "square.stack.3d.up.fill",
                    gradient: [.purple, .indigo]
                ) {
                    // handled via tab
                }
                ToolTile(
                    title: "Tips",
                    subtitle: "Best practices for accurate scans",
                    icon: "lightbulb.fill",
                    gradient: [.yellow, .orange]
                ) {}
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Scans")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if !scanStore.scans.isEmpty {
                    NavigationLink {
                        LibraryView()
                    } label: {
                        Text("See all")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                }
            }

            if scanStore.scans.isEmpty {
                EmptyStateCard()
            } else {
                ForEach(scanStore.scans.prefix(3)) { scan in
                    NavigationLink {
                        ScanDetailView(scan: scan)
                    } label: {
                        ScanRow(scan: scan)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func startRoomScan() {
        if RoomScannerCoordinator.isSupported {
            showingRoomScanner = true
        } else {
            unsupportedMessage = "Room scanning requires a device with a LiDAR sensor (iPhone Pro / Pro Max or iPad Pro)."
            showingUnsupportedAlert = true
        }
    }

    private func startMeasure() {
        if MeasureSession.isSupported {
            showingMeasure = true
        } else {
            unsupportedMessage = "Measuring requires an ARKit-capable device running iOS 13 or later."
            showingUnsupportedAlert = true
        }
    }
}

struct ToolTile: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateCard: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "cube.transparent")
                .font(.system(size: 36))
                .foregroundStyle(.white.opacity(0.5))
            Text("No scans yet")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Tap “Start New Room Scan” to capture your first 3D room.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(ScanStore())
}
