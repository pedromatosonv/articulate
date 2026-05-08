import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct ArticulateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = PracticeStore()

    var body: some Scene {
        WindowGroup("Articulate") {
            ContentView()
                .environmentObject(store)
                .frame(minWidth: 980, minHeight: 660)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Connect") {
                    Task { await store.connect() }
                }
                .keyboardShortcut("k", modifiers: [.command])

                Button("Start Speaking") {
                    Task { await store.startSpeaking() }
                }
                .keyboardShortcut(.space, modifiers: [.command])
                .disabled(!store.canStartSpeaking)

                Button("Stop Speaking") {
                    Task { await store.stopSpeaking() }
                }
                .keyboardShortcut(.space, modifiers: [.command, .shift])
                .disabled(!store.isRecording)
            }
        }

        Settings {
            SettingsView()
                .environmentObject(store)
        }
    }
}
