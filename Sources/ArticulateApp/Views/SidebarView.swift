import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    var body: some View {
        List(selection: $store.selectedMode) {
            Section("Practice") {
                ForEach(PracticeMode.allCases) { mode in
                    Label(mode.title, systemImage: mode.systemImage)
                        .font(.system(size: AppZoom.scaled(13, by: contentScale)))
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
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Articulate")
    }
}
