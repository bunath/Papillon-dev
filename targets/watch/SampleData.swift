import Foundation

/// A small fake week, shown by debug builds until the phone has sent real data,
/// so the screens can be tried in the watch simulator without pairing anything.
enum SampleData {
    static func payload(now: Date = Date(), calendar: Calendar = .current) -> WatchPayload {
        let today = calendar.startOfDay(for: now)

        func at(_ dayOffset: Int, _ hour: Int, _ minute: Int = 0) -> Double {
            let day = calendar.date(byAdding: .day, value: dayOffset, to: today) ?? today
            let date = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
            return date.timeIntervalSince1970 * 1000
        }

        let courses: [WatchCourse] = [
            WatchCourse(id: "s1", subject: "Mathématiques", color: "#C50017", room: "B12",
                        teacher: "M. Martin", start: at(0, 8), end: at(0, 9), canceled: false, info: nil),
            WatchCourse(id: "s2", subject: "Français", color: "#0A7AFF", room: "A03",
                        teacher: "Mme Durand", start: at(0, 9), end: at(0, 10), canceled: false, info: nil),
            WatchCourse(id: "s3", subject: "Éducation physique et sportive", color: "#29947A", room: "Gymnase",
                        teacher: "M. Petit", start: at(0, 10, 15), end: at(0, 12), canceled: true, info: nil),
            WatchCourse(id: "s4", subject: "Histoire-Géographie", color: "#DD6B00", room: "C21",
                        teacher: "Mme Bernard", start: at(0, 14), end: at(0, 15), canceled: false, info: "Salle changée"),
            WatchCourse(id: "s5", subject: "Anglais", color: "#7B3FE4", room: "A10",
                        teacher: "Mr Smith", start: at(0, 15), end: at(0, 16), canceled: false, info: nil),
            WatchCourse(id: "s6", subject: "Physique-Chimie", color: "#00A3A3", room: "L2",
                        teacher: "M. Robert", start: at(1, 8), end: at(1, 10), canceled: false, info: nil),
            WatchCourse(id: "s7", subject: "SVT", color: "#2E9E2E", room: "L1",
                        teacher: "Mme Richard", start: at(1, 10, 15), end: at(1, 11, 15), canceled: false, info: nil),
            WatchCourse(id: "s8", subject: "Mathématiques", color: "#C50017", room: "B12",
                        teacher: "M. Martin", start: at(2, 9), end: at(2, 10), canceled: false, info: nil),
        ]

        let homework: [WatchHomework] = [
            WatchHomework(id: "h1", subject: "Mathématiques", color: "#C50017",
                          content: "Exercices 12 à 15 page 84. Revoir la méthode du discriminant avant le contrôle.",
                          due: at(1, 8), done: false, evaluation: false),
            WatchHomework(id: "h2", subject: "Anglais", color: "#7B3FE4",
                          content: "Apprendre le vocabulaire de l'unité 4 (liste distribuée en cours).",
                          due: at(1, 15), done: true, evaluation: true),
            WatchHomework(id: "h3", subject: "Français", color: "#0A7AFF",
                          content: "Lire le chapitre 3 et préparer un résumé de dix lignes.",
                          due: at(3, 9), done: false, evaluation: false),
            WatchHomework(id: "h4", subject: "Histoire-Géographie", color: "#DD6B00",
                          content: "Terminer la carte mentale sur la décolonisation.",
                          due: at(4, 14), done: false, evaluation: false),
        ]

        return WatchPayload(
            version: 1,
            sentAt: now.timeIntervalSince1970 * 1000,
            courses: courses,
            homework: homework
        )
    }
}
