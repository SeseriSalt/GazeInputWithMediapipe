import Foundation

/// What the UI should do in response to a gesture on a region.
public enum InputAction: Sendable, Equatable {
    case none
    /// Show this character as the pending input.
    case insert(String)
    /// The panel switched to another layout.
    case switchLayout(KeyboardLayout)
    /// Upper- or lower-case the pending character.
    case toggleCase(upper: Bool)
}

/// Combines the selected region with a gesture to produce an input action.
/// Replaces the former `selectionDiscernment` function.
public struct TextComposer: Sendable {
    public private(set) var layout: KeyboardLayout
    public private(set) var isUpperCase = false

    public init(layout: KeyboardLayout = .japanese) {
        self.layout = layout
    }

    public mutating func action(for event: GestureEvent, region: Int) -> InputAction {
        guard region != 0 else { return .none }

        switch event {
        case .blink:
            return .none

        case .wink:
            if region == KeyboardLayout.layoutToggleRegion {
                layout = layout.isAlphabet ? .japanese : .alphabetLower
                isUpperCase = false
                return .switchLayout(layout)
            }
            if layout.isAlphabet, region == KeyboardLayout.caseToggleRegion {
                isUpperCase.toggle()
                return .toggleCase(upper: isUpperCase)
            }
            isUpperCase = false
            guard let character = layout.character(region: region, vowel: 0) else { return .none }
            return .insert(character)

        case .glance(let direction):
            isUpperCase = false
            guard let character = layout.character(region: region, vowel: direction.vowelIndex) else { return .none }
            return .insert(character)
        }
    }

    public mutating func setLayout(_ layout: KeyboardLayout) {
        self.layout = layout
        isUpperCase = false
    }
}
