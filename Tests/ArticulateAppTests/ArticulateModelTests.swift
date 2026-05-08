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
}
