import Foundation

/// The few strings the watch shows, in French and English. The app itself ships
/// many more languages; adding one here is a single extra case per string.
enum Strings {
    private static let french: Bool =
        Locale.preferredLanguages.first?.hasPrefix("fr") ?? false

    private static func pick(_ fr: String, _ en: String) -> String {
        french ? fr : en
    }

    static var timetable: String { pick("Emploi du temps", "Timetable") }
    static var homework: String { pick("Devoirs", "Homework") }

    static var noCourses: String { pick("Aucun cours à venir", "No upcoming classes") }
    static var noHomework: String { pick("Aucun devoir à venir", "No upcoming homework") }
    static var noDetails: String { pick("Pas de détails", "No details") }
    static var waitingForPhone: String {
        pick(
            "Ouvre Papillon sur ton iPhone pour synchroniser",
            "Open Papillon on your iPhone to sync"
        )
    }

    static var ongoing: String { pick("En cours", "Now") }
    static var cancelled: String { pick("Annulé", "Cancelled") }
    static var evaluation: String { pick("Évaluation", "Test") }
    static var done: String { pick("Fait", "Done") }
    static var demo: String { pick("Données de démonstration", "Demo data") }

    static func updated(_ date: Date) -> String {
        let when = date.formatted(.dateTime.day().month(.abbreviated).hour().minute())
        return pick("Mis à jour \(when)", "Updated \(when)")
    }

    /// "Today", "Tomorrow", or "Mon, Oct 20" for the timetable's day headers.
    static func dayTitle(_ day: Date, now: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return pick("Aujourd'hui", "Today")
        }
        if isTomorrow(day, now: now, calendar: calendar) {
            return pick("Demain", "Tomorrow")
        }
        return day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// "Due today", "Due tomorrow", or "Due Mon, Oct 20" for homework.
    static func dueTitle(_ day: Date, now: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: now) {
            return pick("Pour aujourd'hui", "Due today")
        }
        if isTomorrow(day, now: now, calendar: calendar) {
            return pick("Pour demain", "Due tomorrow")
        }
        let date = day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
        return pick("Pour \(date)", "Due \(date)")
    }

    private static func isTomorrow(_ day: Date, now: Date, calendar: Calendar) -> Bool {
        guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) else {
            return false
        }
        return calendar.isDate(day, inSameDayAs: tomorrow)
    }
}
