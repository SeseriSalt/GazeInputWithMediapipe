import Foundation

/// Drives the typing experiment: presents characters one by one and counts how many
/// inputs were needed. Replaces the globals that used to live in `Experiment.swift`.
public struct ExperimentSession: Sendable {
    public enum Outcome: Sendable, Equatable {
        case advanced(next: String)
        /// Questions answered divided by inputs made (1.0 = every input was correct).
        case finished(accuracy: Double)
    }

    public static let alphabetQuestions: [String] = (UnicodeScalar("a").value...UnicodeScalar("z").value)
        .compactMap { UnicodeScalar($0).map { String(Character($0)) } }

    public private(set) var remainingQuestions: [String]
    public private(set) var currentQuestion: String
    /// Inputs made since the warm-up answer, over all questions.
    public private(set) var totalAttempts = 0
    /// Inputs made for the current question.
    public private(set) var attemptsForCurrent = 0
    /// Inputs that were needed for the previous question.
    public private(set) var lastQuestionAttempts = 0
    /// Seconds between the last two correct answers.
    public private(set) var lastAnswerDuration: TimeInterval = 0
    public private(set) var answeredCount = 0

    private let initialQuestions: [String]
    private let firstQuestion: String
    private let randomize: Bool
    private var isFirstAnswer = true
    private var lastAnswerTime: Date?

    public init(questions: [String] = alphabetQuestions, firstQuestion: String = "a", randomize: Bool = true) {
        initialQuestions = questions
        self.firstQuestion = firstQuestion
        self.randomize = randomize
        remainingQuestions = questions
        currentQuestion = firstQuestion
    }

    public var isFinished: Bool { remainingQuestions.isEmpty && !isFirstAnswer && answeredCount > 0 && currentQuestion.isEmpty }

    /// Call whenever the user enters a character.
    public mutating func recordAttempt() {
        attemptsForCurrent += 1
    }

    /// Compares the entered character with the current question. Returns nil when wrong.
    public mutating func check(_ input: String, now: Date = Date()) -> Outcome? {
        guard input == currentQuestion else { return nil }

        lastAnswerDuration = lastAnswerTime.map { now.timeIntervalSince($0) } ?? 0
        lastAnswerTime = now

        if isFirstAnswer {
            // The very first answer is a warm-up and is not counted.
            isFirstAnswer = false
            attemptsForCurrent = 0
            totalAttempts = 0
        } else {
            totalAttempts += attemptsForCurrent
            lastQuestionAttempts = attemptsForCurrent
            attemptsForCurrent = 0
            answeredCount += 1
        }

        guard !remainingQuestions.isEmpty else {
            currentQuestion = ""
            let accuracy = Double(answeredCount) / Double(max(totalAttempts, 1))
            return .finished(accuracy: accuracy)
        }
        let index = randomize ? Int.random(in: 0..<remainingQuestions.count) : 0
        currentQuestion = remainingQuestions.remove(at: index)
        return .advanced(next: currentQuestion)
    }

    public mutating func reset() {
        self = ExperimentSession(questions: initialQuestions, firstQuestion: firstQuestion, randomize: randomize)
    }
}
