import SwiftUI

struct ContentView: View {
    @State private var screen: AppScreen = .practice

    var body: some View {
        ZStack {
            switch screen {
            case .practice:
                NavigationSplitView {
                    SidebarView {
                        showSettings()
                    }
                    .navigationSplitViewColumnWidth(min: 280, ideal: 310, max: 360)
                } detail: {
                    PracticeDetailView()
                }
                .transition(.opacity)

            case .settings:
                SettingsView {
                    showPractice()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: screen)
    }

    private func showSettings() {
        screen = .settings
    }

    private func showPractice() {
        screen = .practice
    }
}

private enum AppScreen {
    case practice
    case settings
}

#Preview {
    ContentView()
        .environmentObject(PracticeStore())
        .environment(\.contentScale, AppZoom.defaultScale)
}
