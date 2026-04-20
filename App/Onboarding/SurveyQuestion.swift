import Foundation

struct SurveyQuestion {
    let promptKey: String
    let options: [(key: String, value: Int)]
}

enum SurveyData {
    static let questions: [SurveyQuestion] = [
        SurveyQuestion(
            promptKey: "onboarding.q1.prompt",
            options: [
                ("onboarding.q1.options.low", 90),
                ("onboarding.q1.options.medium", 210),
                ("onboarding.q1.options.high", 330),
                ("onboarding.q1.options.extreme", 480),
            ]
        ),
        SurveyQuestion(
            promptKey: "onboarding.q2.prompt",
            options: [
                ("onboarding.q2.options.morning", 0),
                ("onboarding.q2.options.afternoon", 1),
                ("onboarding.q2.options.evening", 2),
                ("onboarding.q2.options.allday", 3),
            ]
        ),
        SurveyQuestion(
            promptKey: "onboarding.q3.prompt",
            options: [
                ("onboarding.q3.options.tiktok", 0),
                ("onboarding.q3.options.instagram", 1),
                ("onboarding.q3.options.youtube", 2),
                ("onboarding.q3.options.other", 3),
            ]
        ),
        SurveyQuestion(
            promptKey: "onboarding.q4.prompt",
            options: [
                ("onboarding.q4.options.friends", 0),
                ("onboarding.q4.options.roommates", 1),
                ("onboarding.q4.options.partner", 2),
                ("onboarding.q4.options.coworkers", 3),
            ]
        ),
        SurveyQuestion(
            promptKey: "onboarding.q5.prompt",
            options: [
                ("onboarding.q5.options.60", 60),
                ("onboarding.q5.options.90", 90),
                ("onboarding.q5.options.120", 120),
                ("onboarding.q5.options.180", 180),
            ]
        ),
    ]
}
