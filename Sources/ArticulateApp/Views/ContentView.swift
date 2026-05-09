import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 360)
        } detail: {
            PracticeDetailView()
        }
    }
}
