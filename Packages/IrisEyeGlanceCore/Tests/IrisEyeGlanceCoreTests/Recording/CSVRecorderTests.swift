import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("CSV recorder")
struct CSVRecorderTests {

    private func temporaryFile() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("CSVRecorderTests-\(UUID().uuidString).csv")
    }

    @Test("Header is written once, first row is not lost")
    func headerAndRows() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }

        var recorder = try CSVRecorder(url: url)
        try recorder.append(CSVRow(fields: [("frame", "1"), ("value", "0.5")]))
        try recorder.append(CSVRow(fields: [("frame", "2"), ("value", "0.7")]))
        recorder.close()

        let contents = try String(contentsOf: url, encoding: .utf8)
        let lines = contents.split(separator: "\n").map(String.init)
        #expect(lines == ["frame,value", "1,0.5", "2,0.7"])
    }

    @Test("Rows with a different column set are rejected")
    func mismatchedColumns() throws {
        let url = temporaryFile()
        defer { try? FileManager.default.removeItem(at: url) }

        var recorder = try CSVRecorder(url: url)
        try recorder.append(CSVRow(fields: [("frame", "1")]))
        #expect(throws: CSVRecorder.Error.self) {
            try recorder.append(CSVRow(fields: [("frame", "2"), ("extra", "x")]))
        }
        recorder.close()
    }

    @Test("Fields containing commas or quotes are escaped")
    func escaping() {
        let row = CSVRow(fields: [("a", "1,2"), ("b", "say \"hi\""), ("c", "plain")])
        #expect(row.line == "\"1,2\",\"say \"\"hi\"\"\",plain")
    }

    @Test("Frame results serialise with one value per header column")
    func frameResultColumns() {
        let result = FrameResult(features: EyeFeatures(), thresholds: ThresholdProvider.thresholds(depth: 0, parameters: DetectionParameters()), event: nil, glance: GlanceOutput(glanceDistance: 0, directionDistance: 0, correction: 1, event: nil))
        let row = FrameResultCSV.row(for: result, inputCharacter: "", region: 0)
        #expect(row.fields.count == row.header.count)
        #expect(row.header.first == "frame")
    }
}
