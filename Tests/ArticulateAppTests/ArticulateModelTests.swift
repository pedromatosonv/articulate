import XCTest
@testable import ArticulateApp

final class ArticulateModelTests: XCTestCase {
    func testPracticeModesExposeTitlesAndCoachDirectives() {
        for mode in PracticeMode.allCases {
            XCTAssertFalse(mode.title.isEmpty)
            XCTAssertFalse(mode.systemImage.isEmpty)
            XCTAssertFalse(mode.coachingDirective.isEmpty)
        }
    }

    func testConnectionStatusConnectedFlag() {
        XCTAssertFalse(ConnectionStatus.idle.isConnected)
        XCTAssertFalse(ConnectionStatus.connecting.isConnected)
        XCTAssertTrue(ConnectionStatus.connected.isConnected)
        XCTAssertFalse(ConnectionStatus.failed("x").isConnected)
    }

    func testZoomScaleBoundsAndLabels() {
        XCTAssertEqual(AppZoom.clamped(0.1), AppZoom.minimumScale)
        XCTAssertEqual(AppZoom.clamped(2.0), AppZoom.maximumScale)
        XCTAssertEqual(AppZoom.adjusted(1.0, by: 1), 1.1)
        XCTAssertEqual(AppZoom.adjusted(1.0, by: -1), 0.9)
        XCTAssertEqual(AppZoom.percentLabel(for: 1.2), "120%")
    }

    func testCoachMessageFormatterSplitsLabeledFeedback() {
        let segments = CoachMessageFormatter.segments(
            from: """
            Try this: I spent a lot of time on the bus.
            Why: Use "spent" for past time and "on the bus" for the ride.
            Question: What do you usually do on the bus?
            """
        )

        XCTAssertEqual(segments.count, 3)
        XCTAssertEqual(segments[0].label, "Try this")
        XCTAssertEqual(segments[0].text, "I spent a lot of time on the bus.")
        XCTAssertEqual(segments[1].label, "Why")
        XCTAssertEqual(segments[2].label, "Question")
    }

    func testCoachMessageFormatterKeepsUnlabeledText() {
        let segments = CoachMessageFormatter.segments(from: "Nice answer. What happened next?")

        XCTAssertEqual(segments, [
            CoachMessageSegment(id: 0, label: nil, text: "Nice answer. What happened next?")
        ])
    }

    func testChatSessionRepositoryPersistsSessions() throws {
        let fileURL = temporaryChatHistoryURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let repository = ChatSessionRepository(fileURL: fileURL)
        let session = ChatSession(
            title: "Bus commute correction",
            mode: .conversation,
            proficiency: .intermediate,
            messages: [
                TranscriptItem(role: .learner, text: "Hello", isStreaming: true)
            ]
        )

        try repository.save([session])

        let loadedSessions = try repository.load()
        XCTAssertEqual(loadedSessions.count, 1)
        XCTAssertEqual(loadedSessions[0].title, "Bus commute correction")
        XCTAssertEqual(loadedSessions[0].mode, .conversation)
        XCTAssertEqual(loadedSessions[0].proficiency, .intermediate)
        XCTAssertEqual(loadedSessions[0].messages[0].text, "Hello")
        XCTAssertFalse(loadedSessions[0].messages[0].isStreaming)
    }

    @MainActor
    func testPracticeStorePersistsZoomScale() {
        let suiteName = "ArticulateModelTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let store = PracticeStore(userDefaults: userDefaults)
        XCTAssertEqual(store.contentScale, AppZoom.defaultScale)

        store.setContentScale(1.25)
        XCTAssertEqual(store.contentScale, 1.25)

        let reloadedStore = PracticeStore(userDefaults: userDefaults)
        XCTAssertEqual(reloadedStore.contentScale, 1.25)

        reloadedStore.setContentScale(5)
        XCTAssertEqual(reloadedStore.contentScale, AppZoom.maximumScale)
    }

    @MainActor
    func testPracticeStoreCreatesRenamesSelectsAndDeletesSessions() throws {
        let fileURL = temporaryChatHistoryURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }

        let suiteName = "ArticulateModelTests-\(UUID().uuidString)"
        let userDefaults = UserDefaults(suiteName: suiteName)!
        defer { userDefaults.removePersistentDomain(forName: suiteName) }

        let repository = ChatSessionRepository(fileURL: fileURL)
        let store = PracticeStore(userDefaults: userDefaults, chatRepository: repository)

        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertEqual(store.currentSessionTitle, "New Chat")

        store.renameCurrentSession(to: "Interview warmup")
        XCTAssertEqual(store.currentSessionTitle, "Interview warmup")

        let firstSessionID = try XCTUnwrap(store.selectedSessionID)
        store.createNewSession()
        XCTAssertEqual(store.sessions.count, 2)
        XCTAssertEqual(store.currentSessionTitle, "New Chat")

        store.selectSession(firstSessionID)
        XCTAssertEqual(store.currentSessionTitle, "Interview warmup")

        store.deleteCurrentSession()
        XCTAssertEqual(store.sessions.count, 1)
        XCTAssertNotEqual(store.selectedSessionID, firstSessionID)

        let reloadedSessions = try repository.load()
        XCTAssertEqual(reloadedSessions.count, 1)
    }

    private func temporaryChatHistoryURL() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("ArticulateModelTests-\(UUID().uuidString)", isDirectory: true)
            .appendingPathComponent("chat-sessions.json", isDirectory: false)
    }
}
