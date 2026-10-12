import Foundation

/// How a recognized gesture is shown to the user.
public struct GestureFeedback: Sendable, Equatable {
    public let symbol: String
    public let accessibilityLabel: String

    public static let idle = GestureFeedback(symbol: "___", accessibilityLabel: "入力待ち")

    public init(symbol: String, accessibilityLabel: String) {
        self.symbol = symbol
        self.accessibilityLabel = accessibilityLabel
    }

    public init(event: GestureEvent) {
        switch event {
        case .blink:
            self.init(symbol: "Blink", accessibilityLabel: "まばたき")
        case .wink(.left):
            self.init(symbol: "Wink L", accessibilityLabel: "左ウィンク")
        case .wink(.right):
            self.init(symbol: "Wink R", accessibilityLabel: "右ウィンク")
        case .glance(let direction):
            self.init(symbol: direction.arrow, accessibilityLabel: "\(direction.japaneseName)を一瞥")
        }
    }
}

public extension GlanceDirection {
    var arrow: String {
        switch self {
        case .upperLeft: return "↖︎"
        case .upperRight: return "↗︎"
        case .lowerLeft: return "↙︎"
        case .lowerRight: return "↘︎"
        }
    }

    var japaneseName: String {
        switch self {
        case .upperLeft: return "左上"
        case .upperRight: return "右上"
        case .lowerLeft: return "左下"
        case .lowerRight: return "右下"
        }
    }
}
