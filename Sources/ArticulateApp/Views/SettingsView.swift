import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @State private var selectedSection: SettingsSection = .general

    let onBack: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            settingsSidebar
                .frame(width: AppZoom.scaled(300, by: contentScale))

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: AppZoom.scaled(28, by: contentScale)) {
                    Text(selectedSection.title)
                        .font(.system(size: AppZoom.scaled(24, by: contentScale), weight: .semibold))

                    selectedDetail
                }
                .frame(maxWidth: AppZoom.scaled(760, by: contentScale), alignment: .leading)
                .padding(.horizontal, AppZoom.scaled(52, by: contentScale))
                .padding(.top, AppZoom.scaled(54, by: contentScale))
                .padding(.bottom, AppZoom.scaled(40, by: contentScale))
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        }
        .background(.bar)
        .navigationTitle("Settings")
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(14, by: contentScale)) {
            Button {
                onBack()
            } label: {
                Label("Back to app", systemImage: "chevron.left")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .padding(.top, AppZoom.scaled(42, by: contentScale))

            VStack(spacing: AppZoom.scaled(2, by: contentScale)) {
                ForEach(SettingsSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Label(section.title, systemImage: section.systemImage)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, AppZoom.scaled(10, by: contentScale))
                            .padding(.vertical, AppZoom.scaled(8, by: contentScale))
                            .background(sectionBackground(for: section), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(section == selectedSection ? .primary : .secondary)
                }
            }

            Spacer(minLength: 0)
        }
        .font(.system(size: AppZoom.scaled(14, by: contentScale)))
        .padding(.horizontal, AppZoom.scaled(10, by: contentScale))
    }

    @ViewBuilder
    private var selectedDetail: some View {
        switch selectedSection {
        case .general:
            generalSettings
        case .appearance:
            appearanceSettings
        }
    }

    private var generalSettings: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(18, by: contentScale)) {
            SettingsSectionHeader(
                title: "Current chat",
                subtitle: "Adjust how this practice session behaves."
            )

            SettingsGroup {
                SettingsRow(title: "Mode", subtitle: "Choose the kind of English practice for this chat.") {
                    Picker("Mode", selection: $store.selectedMode) {
                        ForEach(PracticeMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.systemImage)
                                .tag(mode)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: AppZoom.scaled(220, by: contentScale))
                }

                Divider()

                SettingsRow(title: "Level", subtitle: "Set how direct and advanced the coaching should be.") {
                    Picker("Level", selection: $store.proficiency) {
                        ForEach(ProficiencyLevel.allCases) { level in
                            Text(level.title).tag(level)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .frame(width: AppZoom.scaled(180, by: contentScale))
                }
            }
        }
    }

    private var appearanceSettings: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(18, by: contentScale)) {
            SettingsSectionHeader(
                title: "Interface",
                subtitle: "Tune the reading size across chats and controls."
            )

            SettingsGroup {
                SettingsRow(title: "Content zoom", subtitle: "Scale the main app text and controls.") {
                    HStack(spacing: AppZoom.scaled(12, by: contentScale)) {
                        Slider(
                            value: Binding(
                                get: { store.contentScale },
                                set: { store.setContentScale($0) }
                            ),
                            in: AppZoom.minimumScale...AppZoom.maximumScale,
                            step: AppZoom.step
                        )
                        .frame(width: AppZoom.scaled(190, by: contentScale))

                        Text(store.contentScaleLabel)
                            .font(.system(size: AppZoom.scaled(13, by: contentScale), weight: .medium))
                            .monospacedDigit()
                            .frame(width: AppZoom.scaled(44, by: contentScale), alignment: .trailing)

                        Button("Reset") {
                            store.resetZoom()
                        }
                        .disabled(store.contentScale == AppZoom.defaultScale)
                    }
                }
            }
        }
    }

    private func sectionBackground(for section: SettingsSection) -> Color {
        section == selectedSection ? Color.primary.opacity(0.12) : Color.clear
    }
}

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case appearance

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general:
            return "General"
        case .appearance:
            return "Appearance"
        }
    }

    var systemImage: String {
        switch self {
        case .general:
            return "gearshape"
        case .appearance:
            return "sun.max"
        }
    }
}

private struct SettingsSectionHeader: View {
    @Environment(\.contentScale) private var contentScale

    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(6, by: contentScale)) {
            Text(title)
                .font(.system(size: AppZoom.scaled(17, by: contentScale), weight: .semibold))
            Text(subtitle)
                .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                .foregroundStyle(.secondary)
        }
    }
}

private struct SettingsGroup<Content: View>: View {
    @Environment(\.contentScale) private var contentScale

    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(.quaternary.opacity(0.6), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(.quaternary)
        }
    }
}

private struct SettingsRow<Control: View>: View {
    @Environment(\.contentScale) private var contentScale

    let title: String
    let subtitle: String
    @ViewBuilder let control: Control

    var body: some View {
        HStack(alignment: .center, spacing: AppZoom.scaled(18, by: contentScale)) {
            VStack(alignment: .leading, spacing: AppZoom.scaled(4, by: contentScale)) {
                Text(title)
                    .font(.system(size: AppZoom.scaled(14, by: contentScale), weight: .medium))
                Text(subtitle)
                    .font(.system(size: AppZoom.scaled(13, by: contentScale)))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: AppZoom.scaled(20, by: contentScale))

            control
                .frame(alignment: .trailing)
        }
        .padding(.horizontal, AppZoom.scaled(14, by: contentScale))
        .padding(.vertical, AppZoom.scaled(14, by: contentScale))
    }
}
