import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Keyboard layout")
struct KeyboardLayoutTests {

    @Test("Japanese rows follow the gojūon table")
    func japanese() {
        #expect(KeyboardLayout.japanese.character(region: 1, vowel: 0) == "あ")
        #expect(KeyboardLayout.japanese.character(region: 2, vowel: 2) == "く")
        #expect(KeyboardLayout.japanese.character(region: 4, vowel: 0) == "削除")
        #expect(KeyboardLayout.japanese.character(region: 8, vowel: 3) == "空白")
        #expect(KeyboardLayout.japanese.character(region: 15, vowel: 1) == "。")
    }

    @Test("Alphabet rows expose lower and upper case variants")
    func alphabet() {
        #expect(KeyboardLayout.alphabetLower.character(region: 2, vowel: 0) == "a")
        #expect(KeyboardLayout.alphabetUpper.character(region: 2, vowel: 0) == "A")
        #expect(KeyboardLayout.alphabetLower.character(region: 4, vowel: 0) == "delete")
        #expect(KeyboardLayout.alphabetLower.character(region: 11, vowel: 3) == "z")
    }

    @Test("Out-of-range regions and the layout toggle region return nil")
    func invalid() {
        #expect(KeyboardLayout.japanese.character(region: 0, vowel: 0) == nil)
        #expect(KeyboardLayout.japanese.character(region: 16, vowel: 0) == nil)
        #expect(KeyboardLayout.japanese.character(region: 13, vowel: 0) == nil)
        #expect(KeyboardLayout.japanese.character(region: 1, vowel: 5) == nil)
    }

    @Test("Every layout has 15 regions of 5 vowels")
    func shape() {
        for layout in [KeyboardLayout.japanese, .alphabetLower, .alphabetUpper] {
            #expect(layout.rows.count == 15)
            #expect(layout.rows.allSatisfy { $0.count == 5 })
        }
    }
}

@Suite("Input region resolver")
struct InputRegionResolverTests {
    let panel = InputPanelFrame(center: CGPoint(x: 195, y: 422), width: 175, height: 147)

    @Test("Points map to the 15 regions of the 4x4 grid")
    func regions() {
        let resolver = InputRegionResolver(panel: panel)
        #expect(resolver.region(at: CGPoint(x: 120, y: 360)) == 1)
        #expect(resolver.region(at: CGPoint(x: 160, y: 360)) == 2)
        #expect(resolver.region(at: CGPoint(x: 200, y: 360)) == 3)
        #expect(resolver.region(at: CGPoint(x: 250, y: 360)) == 4)
        #expect(resolver.region(at: CGPoint(x: 120, y: 400)) == 5)
        #expect(resolver.region(at: CGPoint(x: 200, y: 440)) == 11)
        #expect(resolver.region(at: CGPoint(x: 250, y: 440)) == 12)
        #expect(resolver.region(at: CGPoint(x: 250, y: 480)) == 12)
        #expect(resolver.region(at: CGPoint(x: 120, y: 480)) == 13)
        #expect(resolver.region(at: CGPoint(x: 160, y: 480)) == 14)
        #expect(resolver.region(at: CGPoint(x: 200, y: 480)) == 15)
    }

    @Test("Points outside the panel resolve to no region")
    func outside() {
        let resolver = InputRegionResolver(panel: panel)
        #expect(resolver.region(at: CGPoint(x: 10, y: 10)) == 0)
        #expect(resolver.region(at: CGPoint(x: 195, y: 600)) == 0)
    }

    @Test("Region rectangles tile the panel, region 12 spans two rows")
    func rects() {
        let resolver = InputRegionResolver(panel: panel)
        let first = resolver.rect(forRegion: 1)
        #expect(first == CGRect(x: 107.5, y: 348.5, width: 43.75, height: 36.75))
        let tall = resolver.rect(forRegion: 12)
        #expect(tall == CGRect(x: 238.75, y: 422, width: 43.75, height: 73.5))
        #expect(resolver.rect(forRegion: 0) == nil)
    }

    @Test("Region change is tracked so the pipeline can gate glances")
    func changeTracking() {
        var tracker = RegionChangeTracker()
        #expect(tracker.update(region: 1, frame: 10) == true)
        #expect(tracker.update(region: 1, frame: 11) == false)
        #expect(tracker.update(region: 2, frame: 12) == true)
        #expect(tracker.lastChangeFrame == 12)
    }
}

@Suite("Text composer")
struct TextComposerTests {

    @Test("Wink inserts the first vowel of the selected row")
    func wink() {
        var composer = TextComposer(layout: .japanese)
        #expect(composer.action(for: .wink(.left), region: 2) == .insert("か"))
    }

    @Test("Glance inserts the vowel of the selected row")
    func glance() {
        var composer = TextComposer(layout: .japanese)
        #expect(composer.action(for: .glance(.upperLeft), region: 1) == .insert("い"))
        #expect(composer.action(for: .glance(.lowerRight), region: 11) == .insert("ろ"))
    }

    @Test("Wink on region 13 toggles between Japanese and alphabet layouts")
    func toggleLayout() {
        var composer = TextComposer(layout: .japanese)
        #expect(composer.action(for: .wink(.left), region: 13) == .switchLayout(.alphabetLower))
        #expect(composer.layout == .alphabetLower)
        #expect(composer.action(for: .wink(.left), region: 13) == .switchLayout(.japanese))
    }

    @Test("Wink on region 1 in the alphabet layout toggles the case of the pending character")
    func toggleCase() {
        var composer = TextComposer(layout: .alphabetLower)
        #expect(composer.action(for: .wink(.left), region: 1) == .toggleCase(upper: true))
        #expect(composer.action(for: .wink(.left), region: 1) == .toggleCase(upper: false))
    }

    @Test("Blink and empty region produce no action")
    func none() {
        var composer = TextComposer(layout: .japanese)
        #expect(composer.action(for: .blink, region: 2) == .none)
        #expect(composer.action(for: .wink(.left), region: 0) == .none)
    }
}
