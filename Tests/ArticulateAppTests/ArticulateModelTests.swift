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
}
