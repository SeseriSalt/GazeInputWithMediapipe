import CoreGraphics
import Foundation

/// Position and size of the input panel in view coordinates.
public struct InputPanelFrame: Sendable, Equatable {
    public var center: CGPoint
    public var width: Double
    public var height: Double

    public init(center: CGPoint, width: Double, height: Double) {
        self.center = center
        self.width = width
        self.height = height
    }

    public var rect: CGRect {
        CGRect(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
}

/// Maps a cursor position to one of the 15 regions of the 4x4 input grid.
///
/// Regions are numbered row by row from the top-left (1...4, 5...8, 9...12, 13...15).
/// Region 12 (last column, third row) spans two rows so the bottom-right cell belongs to it.
public struct InputRegionResolver: Sendable {
    public static let columns = 4
    public static let rows = 4
    /// Region that occupies two rows.
    public static let tallRegion = 12

    public var panel: InputPanelFrame

    public init(panel: InputPanelFrame) {
        self.panel = panel
    }

    private var cellWidth: Double { panel.width / Double(InputRegionResolver.columns) }
    private var cellHeight: Double { panel.height / Double(InputRegionResolver.rows) }
    private var originX: Double { panel.center.x - panel.width / 2 }
    private var originY: Double { panel.center.y - panel.height / 2 }

    /// Region under `point`, or 0 when the point is outside the panel or on a grid line.
    public func region(at point: CGPoint) -> Int {
        guard let column = index(of: point.x, origin: originX, size: cellWidth, count: InputRegionResolver.columns),
              let row = index(of: point.y, origin: originY, size: cellHeight, count: InputRegionResolver.rows) else {
            return 0
        }
        return InputRegionResolver.region(row: row, column: column)
    }

    /// Rectangle of a region in view coordinates, nil for an invalid region.
    public func rect(forRegion region: Int) -> CGRect? {
        guard let (row, column) = InputRegionResolver.cell(forRegion: region) else { return nil }
        let height = region == InputRegionResolver.tallRegion ? cellHeight * 2 : cellHeight
        return CGRect(x: originX + Double(column) * cellWidth,
                      y: originY + Double(row) * cellHeight,
                      width: cellWidth,
                      height: height)
    }

    /// Grid cell (row, column) of a region. The tall region reports its top row.
    public static func cell(forRegion region: Int) -> (row: Int, column: Int)? {
        switch region {
        case 1...12:
            return ((region - 1) / columns, (region - 1) % columns)
        case 13...15:
            return (3, region - 13)
        default:
            return nil
        }
    }

    public static func region(row: Int, column: Int) -> Int {
        if row == 3 {
            return column == 3 ? tallRegion : 13 + column
        }
        return row * columns + column + 1
    }

    /// Strict inequalities mirror the original implementation: a point exactly on a grid
    /// line does not belong to any cell.
    private func index(of value: Double, origin: Double, size: Double, count: Int) -> Int? {
        for index in 0..<count {
            let lower = origin + Double(index) * size
            let upper = lower + size
            if value > lower && value < upper {
                return index
            }
        }
        return nil
    }
}

/// Tracks the selected region frame to frame and remembers when it last changed.
public struct RegionChangeTracker: Sendable {
    public private(set) var currentRegion = 0
    public private(set) var lastChangeFrame = 0

    public init() {}

    /// Returns true when the region differs from the previous frame.
    @discardableResult
    public mutating func update(region: Int, frame: Int) -> Bool {
        defer { currentRegion = region }
        guard region != currentRegion else { return false }
        lastChangeFrame = frame
        return true
    }

    public mutating func reset() {
        self = RegionChangeTracker()
    }
}
