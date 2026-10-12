import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Experiment question sets")
struct QuestionSetTests {

    @Test("Japanese set covers the gojūon table plus the special keys")
    func japanese() {
        let set = ExperimentSession.QuestionSet.japanese
        #expect(set.questions.count == 53)
        #expect(set.questions.first == "あ")
        #expect(set.questions.contains("削除"))
        #expect(set.questions.contains("空白"))
        #expect(set.questions.contains("改行"))
        #expect(set.questions.contains("。"))
        #expect(set.firstQuestion == "あ")
    }

    @Test("Alphabet set is a to z")
    func alphabet() {
        let set = ExperimentSession.QuestionSet.alphabet
        #expect(set.questions.count == 26)
        #expect(set.questions.first == "a")
        #expect(set.questions.last == "z")
        #expect(set.firstQuestion == "a")
    }

    @Test("Every question can be typed on the matching keyboard layout")
    func typeable() {
        for set in ExperimentSession.QuestionSet.allCases {
            let layout = set.layout
            let typeable = Set((1...KeyboardLayout.regionCount).flatMap { region in
                (0..<KeyboardLayout.vowelCount).compactMap { layout.character(region: region, vowel: $0) }
            })
            let missing = set.questions.filter { !typeable.contains($0) }
            #expect(missing.isEmpty, "\(set) cannot type \(missing)")
        }
    }

    @Test("Question set follows the keyboard layout")
    func forLayout() {
        #expect(ExperimentSession.QuestionSet(layout: .japanese) == .japanese)
        #expect(ExperimentSession.QuestionSet(layout: .alphabetLower) == .alphabet)
        #expect(ExperimentSession.QuestionSet(layout: .alphabetUpper) == .alphabet)
    }

    @Test("Session built from a set starts with its first question")
    func session() {
        let session = ExperimentSession(questionSet: .japanese)
        #expect(session.questionSet == .japanese)
        #expect(session.currentQuestion == "あ")
        #expect(session.remainingQuestions.count == 53)
    }
}

@Suite("Keyboard layout preference")
struct KeyboardLayoutPreferenceTests {

    @Test("Round-trips through UserDefaults, upper case is stored as alphabet")
    func persistence() throws {
        let suiteName = "KeyboardLayoutPreferenceTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        #expect(KeyboardLayout.preferred(from: defaults) == .japanese)
        KeyboardLayout.alphabetUpper.savePreference(to: defaults)
        #expect(KeyboardLayout.preferred(from: defaults) == .alphabetLower)
        KeyboardLayout.japanese.savePreference(to: defaults)
        #expect(KeyboardLayout.preferred(from: defaults) == .japanese)
    }

    @Test("Layouts have stable raw values")
    func rawValues() {
        #expect(KeyboardLayout.japanese.rawValue == "japanese")
        #expect(KeyboardLayout.alphabetLower.rawValue == "alphabetLower")
        #expect(KeyboardLayout(rawValue: "alphabetUpper") == .alphabetUpper)
    }
}
