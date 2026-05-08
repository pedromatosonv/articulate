import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: PracticeStore

    var body: some View {
        List(selection: $store.selectedMode) {
            Section("Practice") {
                ForEach(PracticeMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .tag(mode)
                }
            }

            Section("Level") {
                Picker("Level", selection: $store.proficiency) {
                    ForEach(ProficiencyLevel.allCases) { level in
                        Text(level.title).tag(level)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Articulate")
    }
}
