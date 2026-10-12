import Foundation

/// Character tables for the 4x4 input panel. Each of the 15 regions holds five characters,
/// indexed by the vowel number: 0 = wink, 1...4 = glance direction.
public enum KeyboardLayout: Sendable, Equatable, CaseIterable {
    case japanese
    case alphabetLower
    case alphabetUpper

    public static let regionCount = 15
    public static let vowelCount = 5
    /// Region reserved for switching between Japanese and alphabet.
    public static let layoutToggleRegion = 13
    /// Region whose wink toggles the case of the pending character in alphabet layouts.
    public static let caseToggleRegion = 1
    public static let deleteLabel = "削除"
    public static let spaceLabel = "空白"
    public static let newlineLabel = "改行"

    public var rows: [[String]] {
        switch self {
        case .japanese: return KeyboardLayout.japaneseRows
        case .alphabetLower: return KeyboardLayout.alphabetLowerRows
        case .alphabetUpper: return KeyboardLayout.alphabetUpperRows
        }
    }

    public var isAlphabet: Bool { self != .japanese }

    /// Character for a region (1...15) and vowel (0...4). Returns nil for empty cells.
    public func character(region: Int, vowel: Int) -> String? {
        guard (1...KeyboardLayout.regionCount).contains(region), (0..<KeyboardLayout.vowelCount).contains(vowel) else { return nil }
        let value = rows[region - 1][vowel]
        return value.isEmpty ? nil : value
    }

    /// Label shown on the panel for a region (the wink character or the special key name).
    public func label(region: Int) -> String {
        character(region: region, vowel: 0) ?? (region == KeyboardLayout.layoutToggleRegion ? (isAlphabet ? "あ" : "A") : "")
    }

    private static let japaneseRows: [[String]] = [
        ["あ", "い", "う", "え", "お"],
        ["か", "き", "く", "け", "こ"],
        ["さ", "し", "す", "せ", "そ"],
        [deleteLabel, deleteLabel, deleteLabel, deleteLabel, deleteLabel],
        ["た", "ち", "つ", "て", "と"],
        ["な", "に", "ぬ", "ね", "の"],
        ["は", "ひ", "ふ", "へ", "ほ"],
        [spaceLabel, spaceLabel, spaceLabel, spaceLabel, spaceLabel],
        ["ま", "み", "む", "め", "も"],
        ["や", "ゆ", "ゆ", "よ", "よ"],
        ["ら", "り", "る", "れ", "ろ"],
        [newlineLabel, newlineLabel, newlineLabel, newlineLabel, newlineLabel],
        ["", "", "", "", ""],
        ["わ", "を", "を", "ん", "ん"],
        ["、", "。", "？", "！", ""],
    ]

    private static let alphabetLowerRows: [[String]] = [
        ["", "@", "#", "/", "&"],
        ["a", "b", "c", "", ""],
        ["d", "e", "f", "", ""],
        ["delete", "delete", "delete", "delete", "delete"],
        ["g", "h", "i", "", ""],
        ["j", "k", "l", "", ""],
        ["m", "n", "o", "", ""],
        ["space", "space", "space", "space", "space"],
        ["p", "q", "r", "s", ""],
        ["t", "u", "v", "", ""],
        ["w", "x", "y", "z", ""],
        ["↩︎", "↩︎", "↩︎", "↩︎", "↩︎"],
        ["", "", "", "", ""],
        ["'", "\"", "\"", "(", ")"],
        [".", ",", "？", "！", ""],
    ]

    private static let alphabetUpperRows: [[String]] = alphabetLowerRows.map { row in
        row.map { cell in
            cell.count == 1 && cell.first!.isLetter ? cell.uppercased() : cell
        }
    }
}
