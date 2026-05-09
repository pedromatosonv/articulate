import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 360)
        } detail: {
            PracticeDetailView()
        }
        .toolbar {
            ToolbarItemGroup {
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
