import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale
    @State private var isOpeningSettings = false

    let onOpenSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: AppZoom.scaled(12, by: contentScale)) {
                HStack(spacing: AppZoom.scaled(8, by: contentScale)) {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                    Text("Articulate")
                        .font(.system(size: AppZoom.scaled(15, by: contentScale), weight: .semibold))
                    Spacer()
                }

                Button {
                    store.createNewSession()
                } label: {
                    Label("New Chat", systemImage: "plus")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderedProminent)

                TextField("Search chats", text: $store.searchText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: AppZoom.scaled(12, by: contentScale)))
            }
            .padding(.horizontal, AppZoom.scaled(14, by: contentScale))
            .padding(.top, AppZoom.scaled(14, by: contentScale))
            .padding(.bottom, AppZoom.scaled(10, by: contentScale))

            ScrollView {
                LazyVStack(alignment: .leading, spacing: AppZoom.scaled(14, by: contentScale)) {
                    ForEach(historyGroups, id: \.title) { group in
                        if !group.sessions.isEmpty {
                            HistorySectionView(title: group.title, sessions: group.sessions)
                        }
                    }
                }
                .padding(.horizontal, AppZoom.scaled(10, by: contentScale))
                .padding(.vertical, AppZoom.scaled(4, by: contentScale))
            }

            Spacer(minLength: 0)

            Divider()

            Button {
                openSettings()
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .font(.system(size: AppZoom.scaled(13, by: contentScale)))
            .padding(AppZoom.scaled(14, by: contentScale))
            .opacity(isOpeningSettings ? 0.45 : 1)
            .animation(.easeOut(duration: 0.12), value: isOpeningSettings)
        }
        .navigationTitle("")
    }

    private func openSettings() {
        guard !isOpeningSettings else { return }
        isOpeningSettings = true

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 90_000_000)
            onOpenSettings()
            isOpeningSettings = false
        }
    }

    private var historyGroups: [HistoryGroup] {
        let calendar = Calendar.current
        let now = Date()
        let sessions = store.filteredSessions

        return [
            HistoryGroup(
                title: "Today",
                sessions: sessions.filter { calendar.isDateInToday($0.updatedAt) }
            ),
            HistoryGroup(
                title: "Yesterday",
                sessions: sessions.filter { calendar.isDateInYesterday($0.updatedAt) }
            ),
            HistoryGroup(
                title: "Previous 7 Days",
                sessions: sessions.filter { session in
                    guard !calendar.isDateInToday(session.updatedAt),
                          !calendar.isDateInYesterday(session.updatedAt),
                          let days = calendar.dateComponents([.day], from: session.updatedAt, to: now).day else {
                        return false
                    }
                    return days < 7
                }
            ),
            HistoryGroup(
                title: "Older",
                sessions: sessions.filter { session in
                    guard let days = calendar.dateComponents([.day], from: session.updatedAt, to: now).day else {
                        return false
                    }
                    return days >= 7
                }
            )
        ]
    }
}

private struct HistoryGroup {
    let title: String
    let sessions: [ChatSession]
}

private struct HistorySectionView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    let title: String
    let sessions: [ChatSession]

    var body: some View {
        VStack(alignment: .leading, spacing: AppZoom.scaled(6, by: contentScale)) {
            Text(title)
                .font(.system(size: AppZoom.scaled(11, by: contentScale), weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, AppZoom.scaled(8, by: contentScale))

            ForEach(sessions) { session in
                HistoryRowView(session: session, isSelected: store.selectedSessionID == session.id)
            }
        }
    }
}

private struct HistoryRowView: View {
    @EnvironmentObject private var store: PracticeStore
    @Environment(\.contentScale) private var contentScale

    let session: ChatSession
    let isSelected: Bool

    var body: some View {
        Button {
            store.selectSession(session.id)
        } label: {
            HStack(spacing: AppZoom.scaled(10, by: contentScale)) {
                Image(systemName: session.mode.systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: AppZoom.scaled(16, by: contentScale))

                VStack(alignment: .leading, spacing: AppZoom.scaled(2, by: contentScale)) {
                    Text(session.title)
                        .lineLimit(1)
                        .foregroundStyle(.primary)

                    Text("\(relativeDate(for: session.updatedAt)) · \(session.mode.title)")
                        .font(.system(size: AppZoom.scaled(11, by: contentScale)))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Menu {
                        Button("Clear Chat") {
                            store.clearTranscript()
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            store.deleteCurrentSession()
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(.secondary)
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()
                }
            }
            .font(.system(size: AppZoom.scaled(13, by: contentScale)))
            .padding(.horizontal, AppZoom.scaled(8, by: contentScale))
            .padding(.vertical, AppZoom.scaled(8, by: contentScale))
            .background(rowBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button("Select") {
                store.selectSession(session.id)
            }
            Button("Clear Chat") {
                store.selectSession(session.id)
                store.clearTranscript()
            }
            Divider()
            Button("Delete", role: .destructive) {
                store.selectSession(session.id)
                store.deleteCurrentSession()
            }
        }
    }

    private var rowBackground: Color {
        isSelected ? Color.accentColor.opacity(0.22) : Color.clear
    }

    private func relativeDate(for date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
