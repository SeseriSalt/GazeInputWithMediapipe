import CoreGraphics
import Foundation

/// Available sizes of the input panel. Double-tapping the panel cycles through them.
public enum PanelSizePreset: CaseIterable, Sendable, Equatable {
    case standard
    case large
    case compact

    public var size: CGSize {
        switch self {
        case .standard: return CGSize(width: 175, height: 147)
        case .large: return CGSize(width: 200, height: 168)
        case .compact: return CGSize(width: 150, height: 126)
        }
    }

    /// Size of the glance-hint overlay shown over the hovered cell.
    public var hintSize: CGSize {
        switch self {
        case .standard: return CGSize(width: 87, height: 73)
        case .large: return CGSize(width: 127, height: 106)
        case .compact: return CGSize(width: 75, height: 63)
        }
    }

    public var lineWidth: Double {
        switch self {
        case .standard, .large: return 1.5
        case .compact: return 1.25
        }
    }

    public var next: PanelSizePreset {
        let all = PanelSizePreset.allCases
        let index = all.firstIndex(of: self) ?? 0
        return all[(index + 1) % all.count]
    }
}
