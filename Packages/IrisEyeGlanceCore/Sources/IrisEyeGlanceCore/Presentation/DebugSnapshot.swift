import Foundation

/// Compact textual view of one frame for the debug overlay.
public struct DebugSnapshot: Sendable, Equatable {
    public let lines: [String]

    public var text: String { lines.joined(separator: "\n") }

    public init(result: FrameResult, cameraFrames: Int, region: Int) {
        let f = result.features
        let t = result.thresholds
        let g = result.glance
        func s(_ value: Double) -> String { String(format: "%.2f", value) }
        var lines = [
            "frame \(f.frame) / camera \(cameraFrames)",
            "depth \(String(format: "%.1f", f.thresholdDepth / 10)) cm",
            "lid LR \(s(f.eyelidDiffLR)) (min \(s(t.winkMin)) max \(s(t.winkMax)))",
            "glance \(s(g.glanceDistance)) (min \(s(t.glanceMin)) max \(s(t.glanceMax)))",
            "areas up \(s(result.winkAreaUp)) down \(s(result.winkAreaDown))",
            "region \(region)",
        ]
        if let event = result.event {
            lines.append("event \(GestureFeedback(event: event).symbol)")
        }
        self.lines = lines
    }
}
