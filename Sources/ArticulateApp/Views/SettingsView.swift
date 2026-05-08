import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        Form {
            Picker("Default mode", selection: $store.selectedMode) {
                ForEach(PracticeMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }

            Picker("Level", selection: $store.proficiency) {
                ForEach(ProficiencyLevel.allCases) { level in
                    Text(level.title).tag(level)
                }
            }

            HStack {
                Text("Content zoom")
                Slider(
                    value: Binding(
                        get: { store.contentScale },
                        set: { store.setContentScale($0) }
                    ),
                    in: AppZoom.minimumScale...AppZoom.maximumScale,
                    step: AppZoom.step
                )
                Text(store.contentScaleLabel)
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
                Button("Reset") {
                    store.resetZoom()
                }
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
