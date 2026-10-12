import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Panel size preset")
struct PanelSizePresetTests {

    @Test("Presets keep the sizes of the original image panel and cycle in order")
    func sizes() {
        #expect(PanelSizePreset.standard.size == CGSize(width: 175, height: 147))
        #expect(PanelSizePreset.large.size == CGSize(width: 200, height: 168))
        #expect(PanelSizePreset.compact.size == CGSize(width: 150, height: 126))
        #expect(PanelSizePreset.standard.next == .large)
        #expect(PanelSizePreset.large.next == .compact)
        #expect(PanelSizePreset.compact.next == .standard)
    }

    @Test("Line width and hint size scale with the preset")
    func lineWidth() {
        #expect(PanelSizePreset.standard.lineWidth == 1.5)
        #expect(PanelSizePreset.compact.lineWidth == 1.25)
        #expect(PanelSizePreset.large.hintSize == CGSize(width: 127, height: 106))
    }
}

@Suite("Input panel layout model")
struct InputPanelLayoutModelTests {
    let frame = InputPanelFrame(center: CGPoint(x: 195, y: 422), width: 175, height: 147)

    @Test("Every region has a cell with a title or symbol")
    func cells() {
        let model = InputPanelLayoutModel(layout: .japanese, frame: frame)
        #expect(model.cells.count == 15)
        #expect(model.cells.allSatisfy { $0.title != nil || $0.symbolName != nil })
        #expect(model.cell(forRegion: 1)?.title == "あ")
        #expect(model.cell(forRegion: 2)?.title == "か")
        #expect(model.cell(forRegion: 14)?.title == "わ")
        #expect(model.cell(forRegion: 15)?.title == "、")
    }

    @Test("Special keys use glyphs and are marked so they can be tinted")
    func specialKeys() {
        let japanese = InputPanelLayoutModel(layout: .japanese, frame: frame)
        #expect(japanese.cell(forRegion: 4)?.symbolName == "delete.left.fill")
        #expect(japanese.cell(forRegion: 4)?.isSpecial == true)
        #expect(japanese.cell(forRegion: 8)?.title == "空白")
        #expect(japanese.cell(forRegion: 12)?.title == "改行")
        #expect(japanese.cell(forRegion: 13)?.symbolName == "globe")
        #expect(japanese.cell(forRegion: 1)?.isSpecial == false)

        let alphabet = InputPanelLayoutModel(layout: .alphabetLower, frame: frame)
        #expect(alphabet.cell(forRegion: 1)?.title == "a/A")
        #expect(alphabet.cell(forRegion: 2)?.title == "A")
        #expect(alphabet.cell(forRegion: 8)?.symbolName == "space")
        #expect(alphabet.cell(forRegion: 12)?.symbolName == "return")
    }

    @Test("Cell rects come from the region resolver, region 12 is tall")
    func rects() {
        let model = InputPanelLayoutModel(layout: .japanese, frame: frame)
        #expect(model.cell(forRegion: 1)?.rect == CGRect(x: 107.5, y: 348.5, width: 43.75, height: 36.75))
        #expect(model.cell(forRegion: 12)?.rect.height == 73.5)
    }

    @Test("Glance hints list the four corner characters of a region")
    func hints() {
        let japanese = InputPanelLayoutModel(layout: .japanese, frame: frame)
        #expect(japanese.glanceHints(forRegion: 1) == ["い", "う", "え", "お"])
        #expect(japanese.glanceHints(forRegion: 4) == nil)
        #expect(japanese.glanceHints(forRegion: 13) == nil)
        let alphabet = InputPanelLayoutModel(layout: .alphabetLower, frame: frame)
        #expect(alphabet.glanceHints(forRegion: 2) == ["b", "c", "", ""])
        #expect(alphabet.glanceHints(forRegion: 0) == nil)
    }
}

@Suite("Gesture feedback")
struct GestureFeedbackTests {

    @Test("Glances map to corner arrows")
    func glance() {
        #expect(GestureFeedback(event: .glance(.upperLeft)).symbol == "↖︎")
        #expect(GestureFeedback(event: .glance(.upperRight)).symbol == "↗︎")
        #expect(GestureFeedback(event: .glance(.lowerLeft)).symbol == "↙︎")
        #expect(GestureFeedback(event: .glance(.lowerRight)).symbol == "↘︎")
        #expect(GestureFeedback(event: .glance(.upperLeft)).accessibilityLabel == "左上を一瞥")
    }

    @Test("Winks and blinks are labelled")
    func winkAndBlink() {
        #expect(GestureFeedback(event: .wink(.left)).symbol == "Wink L")
        #expect(GestureFeedback(event: .wink(.right)).symbol == "Wink R")
        #expect(GestureFeedback(event: .blink).symbol == "Blink")
        #expect(GestureFeedback(event: .wink(.left)).accessibilityLabel == "左ウィンク")
        #expect(GestureFeedback(event: .blink).accessibilityLabel == "まばたき")
    }

    @Test("Idle feedback is a placeholder")
    func idle() {
        #expect(GestureFeedback.idle.symbol == "___")
        #expect(GestureFeedback.idle.accessibilityLabel == "入力待ち")
    }
}

@Suite("Calibration presentation")
struct CalibrationPresentationTests {

    @Test("Idle shows the calibration button and the panel")
    func idle() {
        let presentation = CalibrationPresentation(step: .idle)
        #expect(presentation.buttonTitle == "Calibration")
        #expect(!presentation.hidesInputPanel)
        #expect(presentation.progress == 0)
        #expect(presentation.instruction.isEmpty)
    }

    @Test("Rest step explains the distance and hides the panel")
    func rest() {
        let presentation = CalibrationPresentation(step: .restIntro)
        #expect(presentation.instruction.contains("30cm"))
        #expect(presentation.centerSymbol == "＋")
        #expect(presentation.buttonTitle == "Start")
        #expect(presentation.hidesInputPanel)
    }

    @Test("Arrow steps cycle through the four corners and advance the progress")
    func arrows() {
        #expect(CalibrationPresentation(step: .arrow(0)).centerSymbol == "↖︎")
        #expect(CalibrationPresentation(step: .arrow(1)).centerSymbol == "↗︎")
        #expect(CalibrationPresentation(step: .arrow(2)).centerSymbol == "↙︎")
        #expect(CalibrationPresentation(step: .arrow(3)).centerSymbol == "↘︎")
        #expect(CalibrationPresentation(step: .arrow(4)).centerSymbol == "↖︎")
        #expect(CalibrationPresentation(step: .arrow(0)).buttonTitle == "Next")
        let early = CalibrationPresentation(step: .arrow(0)).progress
        let late = CalibrationPresentation(step: .arrow(7)).progress
        #expect(early > 0 && late > early && late < 1)
        #expect(CalibrationPresentation(step: .arrow(0)).stepDescription == "1 / 8")
    }

    @Test("Done offers to close and reports full progress")
    func done() {
        let presentation = CalibrationPresentation(step: .done)
        #expect(presentation.buttonTitle == "閉じる")
        #expect(presentation.progress == 1)
        #expect(presentation.instruction.contains("入力できます"))
    }
}

@Suite("Debug snapshot")
struct DebugSnapshotTests {

    @Test("Formats the frame state as short lines")
    func lines() {
        var features = EyeFeatures()
        features.frame = 12
        features.thresholdDepth = 305
        features.eyelidDiffLR = -0.123
        let thresholds = ThresholdProvider.thresholds(depth: 305, parameters: DetectionParameters())
        let result = FrameResult(features: features, thresholds: thresholds, event: .blink,
                                 glance: GlanceOutput(glanceDistance: -0.3, directionDistance: 0, correction: 1, event: nil))
        let snapshot = DebugSnapshot(result: result, cameraFrames: 30, region: 5)
        #expect(snapshot.lines.first == "frame 12 / camera 30")
        #expect(snapshot.lines.contains("depth 30.5 cm"))
        #expect(snapshot.lines.contains { $0.hasPrefix("lid LR -0.12") })
        #expect(snapshot.lines.contains { $0.hasPrefix("glance -0.30") })
        #expect(snapshot.lines.contains("region 5"))
        #expect(snapshot.lines.contains("event Blink"))
        #expect(snapshot.text == snapshot.lines.joined(separator: "\n"))
    }
}
