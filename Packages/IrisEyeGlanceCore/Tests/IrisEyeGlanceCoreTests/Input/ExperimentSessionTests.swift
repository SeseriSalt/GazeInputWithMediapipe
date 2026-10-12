import Foundation
import Testing
@testable import IrisEyeGlanceCore

@Suite("Experiment session")
struct ExperimentSessionTests {

    @Test("Presents questions until the list is exhausted and reports accuracy")
    func flow() {
        var session = ExperimentSession(questions: ["a", "b"], firstQuestion: "a")
        #expect(session.currentQuestion == "a")

        session.recordAttempt()
        #expect(session.check("x") == nil)          // wrong character, keep going
        session.recordAttempt()
        let first = session.check("a")
        #expect(first == .advanced(next: "b") || first == .advanced(next: "a"))
        #expect(session.remainingQuestions.count == 1)

        session.recordAttempt()
        let second = session.check(session.currentQuestion)
        if case .advanced = second {} else { Issue.record("expected another question") }

        session.recordAttempt()
        let last = session.check(session.currentQuestion)
        #expect(last == .finished(accuracy: 3.0 / 3.0))
    }

    @Test("First correct answer resets counters so warm-up input is not counted")
    func warmup() {
        var session = ExperimentSession(questions: ["b"], firstQuestion: "a")
        session.recordAttempt()
        session.recordAttempt()
        _ = session.check("a")
        #expect(session.totalAttempts == 0)
    }

    @Test("reset restores the initial question list")
    func reset() {
        var session = ExperimentSession(questions: ["b"], firstQuestion: "a")
        _ = session.check("a")
        session.reset()
        #expect(session.currentQuestion == "a")
        #expect(session.remainingQuestions == ["b"])
    }
}
