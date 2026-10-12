import Foundation

/// Drives the typing experiment: presents characters one by one and counts how many
/// inputs were needed. Replaces the globals that used to live in `Experiment.swift`.
public struct ExperimentSession: Sendable {
    public enum Outcome: Sendable, Equatable {
        case advanced(next: String)
        /// Questions answered divided by inputs made (1.0 = every input was correct).
        case finished(accuracy: Double)
    }

    /// Which characters are presented. Each set matches one keyboard layout so that
    /// every question can actually be typed.
    public enum QuestionSet: String, CaseIterable, Sendable, Equatable {
        case japanese
        case alphabet

        public init(layout: KeyboardLayout) {
            self = layout.isAlphabet ? .alphabet : .japanese
        }

        public var layout: KeyboardLayout {
            switch self {
            case .japanese: return .japanese
            case .alphabet: return .alphabetLower
            }
        }

        public var firstQuestion: String {
            questions[0]
        }

        public var questions: [String] {
            switch self {
            case .japanese: return ExperimentSession.japaneseQuestions
            case .alphabet: return ExperimentSession.alphabetQuestions
            }
        }
    }

    public static let alphabetQuestions: [String] = (UnicodeScalar("a").value...UnicodeScalar("z").value)
        .compactMap { UnicodeScalar($0).map { String(Character($0)) } }

    /// Gojūon table in panel order including the special keys, as used in the original experiment.
    public static let japaneseQuestions: [String] = [
        "あ", "い", "う", "え", "お",
        "か", "き", "く", "け", "こ",
        "さ", "し", "す", "せ", "そ",
        KeyboardLayout.deleteLabel,
        "た", "ち", "つ", "て", "と",
        "な", "に", "ぬ", "ね", "の",
        "は", "ひ", "ふ", "へ", "ほ",
        KeyboardLayout.spaceLabel,
        "ま", "み", "む", "め", "も",
        "や", "ゆ", "よ",
        "ら", "り", "る", "れ", "ろ",
        KeyboardLayout.newlineLabel,
        "わ", "を", "ん",
        "、", "。", "？", "！",
    ]

    public let questionSet: QuestionSet?
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
        questionSet = nil
        initialQuestions = questions
        self.firstQuestion = firstQuestion
        self.randomize = randomize
        remainingQuestions = questions
        currentQuestion = firstQuestion
    }

    public init(questionSet: QuestionSet, randomize: Bool = true) {
        self.questionSet = questionSet
        initialQuestions = questionSet.questions
        firstQuestion = questionSet.firstQuestion
        self.randomize = randomize
        remainingQuestions = questionSet.questions
        currentQuestion = questionSet.firstQuestion
    }

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
        if let questionSet {
            self = ExperimentSession(questionSet: questionSet, randomize: randomize)
        } else {
            self = ExperimentSession(questions: initialQuestions, firstQuestion: firstQuestion, randomize: randomize)
        }
    }
}
