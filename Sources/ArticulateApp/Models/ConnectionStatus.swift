import Foundation

enum ConnectionStatus: Equatable {
    case idle
    case connecting
    case connected
    case failed(String)

    var title: String {
        switch self {
        case .idle:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .failed:
            return "Needs attention"
        }
    }

    var isConnected: Bool {
        if case .connected = self {
            return true
        }
        return false
    }
}

