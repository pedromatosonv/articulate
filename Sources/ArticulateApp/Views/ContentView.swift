import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 220, ideal: 260, max: 320)
        } detail: {
            PracticeDetailView()
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    Task {
                        if store.connectionStatus.isConnected {
                            await store.disconnect()
                        } else {
                            await store.connect()
                        }
                    }
                } label: {
                    Label(store.connectionStatus.isConnected ? "Disconnect" : "Connect", systemImage: store.connectionStatus.isConnected ? "bolt.horizontal.circle.fill" : "bolt.horizontal.circle")
                }

                Button {
                    store.clearTranscript()
                } label: {
                    Label("Clear", systemImage: "trash")
                }
                .disabled(store.transcript.isEmpty)

                Divider()

                Button {
                    store.zoomOut()
                } label: {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                }
                .disabled(!store.canZoomOut)

                Button {
                    store.resetZoom()
                } label: {
                    Label(store.contentScaleLabel, systemImage: "textformat.size")
                }
                .help("Reset Zoom")

                Button {
                    store.zoomIn()
                } label: {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                }
                .disabled(!store.canZoomIn)
            }
        }
    }
}
