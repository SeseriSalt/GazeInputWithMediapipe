import Foundation

/// One CSV row: ordered (column name, value) pairs. The header is derived from the same
/// list, so the two can never drift apart.
public struct CSVRow: Sendable {
    public let fields: [(name: String, value: String)]

    public init(fields: [(String, String)]) {
        self.fields = fields.map { (name: $0.0, value: $0.1) }
    }

    public var header: [String] { fields.map(\.name) }

    public var headerLine: String { header.map(CSVRow.escape).joined(separator: ",") }

    public var line: String { fields.map { CSVRow.escape($0.value) }.joined(separator: ",") }

    static func escape(_ value: String) -> String {
        guard value.contains(",") || value.contains("\"") || value.contains("\n") else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
}

/// Appends rows to a CSV file, writing the header before the first row.
public struct CSVRecorder {
    public enum Error: Swift.Error, Equatable {
        case columnMismatch(expected: [String], actual: [String])
    }

    public let url: URL
    private let handle: FileHandle
    private var header: [String]?

    public init(url: URL) throws {
        self.url = url
        if !FileManager.default.fileExists(atPath: url.path) {
            FileManager.default.createFile(atPath: url.path, contents: nil)
        }
        handle = try FileHandle(forWritingTo: url)
        try handle.seekToEnd()
    }

    public mutating func append(_ row: CSVRow) throws {
        if let header {
            guard header == row.header else {
                throw Error.columnMismatch(expected: header, actual: row.header)
            }
        } else {
            header = row.header
            try handle.write(contentsOf: Data((row.headerLine + "\n").utf8))
        }
        try handle.write(contentsOf: Data((row.line + "\n").utf8))
    }

    public func close() {
        try? handle.close()
    }
}

/// Serialises a `FrameResult` for the experiment logs.
public enum FrameResultCSV {
    public static func row(for result: FrameResult, inputCharacter: String, region: Int) -> CSVRow {
        let f = result.features
        let t = result.thresholds
        let g = result.glance
        func s(_ value: Double) -> String { String(format: "%.6f", value) }
        return CSVRow(fields: [
            ("frame", String(f.frame)),
            ("inputCharacter", inputCharacter),
            ("region", String(region)),
            ("event", result.event.map { String($0.legacyCode) } ?? ""),
            ("leftEyelidDiff", s(f.leftEyelidDiff)),
            ("rightEyelidDiff", s(f.rightEyelidDiff)),
            ("depthCm", s(f.thresholdDepth / 10)),
            ("eyelidHeightDiffLR", s(f.eyelidHeightDiffLR)),
            ("eyelidDiffLR", s(f.eyelidDiffLR)),
            ("winkMin", s(t.winkMin)),
            ("winkMax", s(t.winkMax)),
            ("winkAreaUp", s(result.winkAreaUp)),
            ("winkAreaDown", s(result.winkAreaDown)),
            ("winkAreaMin", s(t.winkAreaMin)),
            ("winkAreaMax", s(t.winkAreaMax)),
            ("blinkThreshold", s(t.blink)),
            ("leftIrisDeltaY", s(f.leftIrisDelta2.y)),
            ("rightIrisDeltaY", s(f.rightIrisDelta2.y)),
            ("glanceDistance", s(g.glanceDistance)),
            ("glanceMin", s(t.glanceMin)),
            ("glanceMax", s(t.glanceMax)),
            ("glanceCorrection", s(g.correction)),
            ("glanceAreaDownThreshold", s(t.glanceAreaDown)),
            ("glanceAreaUpThreshold", s(t.glanceAreaUp)),
            ("leftIrisDeltaX", s(f.leftIrisDelta2.x)),
            ("rightIrisDeltaX", s(f.rightIrisDelta2.x)),
            ("directionDistance", s(g.directionDistance)),
            ("filteredReferenceDeltaY", s(f.filteredReferenceDeltaY)),
            ("rawReferenceDeltaY", s(f.rawReferenceDeltaY)),
        ])
    }
}
