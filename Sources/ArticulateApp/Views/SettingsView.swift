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
                Text("Voice speed")
                Slider(value: $store.speed, in: 0.75...1.25, step: 0.05)
                Text(store.speed.formatted(.number.precision(.fractionLength(2))))
                    .monospacedDigit()
                    .frame(width: 42, alignment: .trailing)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}

