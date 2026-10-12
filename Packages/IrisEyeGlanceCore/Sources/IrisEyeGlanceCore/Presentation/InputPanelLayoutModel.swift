import CoreGraphics
import Foundation

/// Everything a view needs to draw the input panel: one cell per region with its
/// rectangle, label and whether it is a special key.
public struct InputPanelLayoutModel: Sendable, Equatable {

    public struct Cell: Sendable, Equatable {
        public var region: Int
        public var rect: CGRect
        /// Text label, nil when a symbol is used instead.
        public var title: String?
        /// SF Symbol name, nil when a text label is used.
        public var symbolName: String?
        /// Special keys (delete, space, newline, layout toggle) are drawn tinted.
        public var isSpecial: Bool
    }

    public let layout: KeyboardLayout
    public let frame: InputPanelFrame
    public let cells: [Cell]

    public init(layout: KeyboardLayout, frame: InputPanelFrame) {
        self.layout = layout
        self.frame = frame
        let resolver = InputRegionResolver(panel: frame)
        cells = (1...KeyboardLayout.regionCount).compactMap { region in
            guard let rect = resolver.rect(forRegion: region) else { return nil }
            let (title, symbol, special) = InputPanelLayoutModel.label(layout: layout, region: region)
            return Cell(region: region, rect: rect, title: title, symbolName: symbol, isSpecial: special)
        }
    }

    public func cell(forRegion region: Int) -> Cell? {
        cells.first { $0.region == region }
    }

    /// Characters entered by glancing to the four corners while this region is selected,
    /// in the order upper-left, upper-right, lower-left, lower-right. Nil for special keys.
    public func glanceHints(forRegion region: Int) -> [String]? {
        guard let cell = cell(forRegion: region), !cell.isSpecial else { return nil }
        return GlanceDirection.allCases.map { layout.character(region: region, vowel: $0.vowelIndex) ?? "" }
    }

    private static func label(layout: KeyboardLayout, region: Int) -> (title: String?, symbol: String?, special: Bool) {
        if region == KeyboardLayout.layoutToggleRegion {
            return (nil, "globe", true)
        }
        let character = layout.character(region: region, vowel: 0) ?? ""
        switch character {
        case KeyboardLayout.deleteLabel, "delete":
            return (nil, "delete.left.fill", true)
        case KeyboardLayout.spaceLabel:
            return (character, nil, true)
        case "space":
            return (nil, "space", true)
        case KeyboardLayout.newlineLabel:
            return (character, nil, true)
        case "↩︎":
            return (nil, "return", true)
        default:
            break
        }
        if layout.isAlphabet, region == KeyboardLayout.caseToggleRegion {
            return ("a/A", nil, false)
        }
        if layout.isAlphabet, character.count == 1, character.first!.isLetter {
            // The panel shows the row's first letter in upper case like a phone keypad.
            return (character.uppercased(), nil, false)
        }
        return (character, nil, false)
    }
}
