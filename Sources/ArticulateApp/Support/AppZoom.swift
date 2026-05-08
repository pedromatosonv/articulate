import Foundation
import SwiftUI

enum AppZoom {
    static let storageKey = "articulate.contentScale"
    static let defaultScale = 1.0
    static let minimumScale = 0.8
    static let maximumScale = 1.5
    static let step = 0.1

    static func clamped(_ value: Double) -> Double {
        min(max(value, minimumScale), maximumScale)
    }

    static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }

    static func adjusted(_ value: Double, by steps: Int) -> Double {
        rounded(clamped(value + Double(steps) * step))
    }

    static func percentLabel(for value: Double) -> String {
        "\(Int((clamped(value) * 100).rounded()))%"
    }

    static func scaled(_ base: CGFloat, by scale: Double) -> CGFloat {
        base * CGFloat(clamped(scale))
    }
}

private struct ContentScaleKey: EnvironmentKey {
    static let defaultValue = AppZoom.defaultScale
}

extension EnvironmentValues {
    var contentScale: Double {
        get { self[ContentScaleKey.self] }
        set { self[ContentScaleKey.self] = AppZoom.clamped(newValue) }
    }
}

