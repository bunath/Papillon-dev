import Foundation

struct CourseDay: Identifiable, Equatable {
    let day: Date
    let courses: [WatchCourse]

    var id: Date { day }
}

struct HomeworkDay: Identifiable, Equatable {
    let day: Date
    let items: [WatchHomework]

    var id: Date { day }
}

enum CourseState: Equatable {
    case finished
    case ongoing
    case upcoming
}

/// Pure logic behind the lists. It only needs Foundation, so it can be tested
/// without a simulator.
enum Schedule {
    /// Groups courses by the day they start, from today on, in start order.
    static func days(
        from courses: [WatchCourse],
        now: Date,
        calendar: Calendar = .current
    ) -> [CourseDay] {
        let today = calendar.startOfDay(for: now)
        let grouped = Dictionary(grouping: courses) { course in
            calendar.startOfDay(for: course.startDate)
        }

        return grouped
            .filter { $0.key >= today }
            .map { entry -> CourseDay in
                let sorted = entry.value.sorted { lhs, rhs in
                    if lhs.start != rhs.start {
                        return lhs.start < rhs.start
                    }
                    return lhs.end < rhs.end
                }
                return CourseDay(day: entry.key, courses: sorted)
            }
            .sorted { $0.day < $1.day }
    }

    static func state(of course: WatchCourse, now: Date) -> CourseState {
        if course.endDate <= now {
            return .finished
        }
        if course.startDate <= now {
            return .ongoing
        }
        return .upcoming
    }

    /// The course to bring into view: the one under way, else the next one to
    /// start. Cancelled courses are skipped, there is nothing to attend.
    static func focus(in days: [CourseDay], now: Date) -> WatchCourse? {
        for day in days {
            if let course = day.courses.first(where: { !$0.canceled && $0.endDate > now }) {
                return course
            }
        }
        return nil
    }

    /// Groups homework by due day, from today on. Within a day, what is still
    /// to do comes before what is done.
    static func homeworkDays(
        from items: [WatchHomework],
        now: Date,
        calendar: Calendar = .current
    ) -> [HomeworkDay] {
        let today = calendar.startOfDay(for: now)
        let grouped = Dictionary(grouping: items) { item in
            calendar.startOfDay(for: item.dueDate)
        }

        return grouped
            .filter { $0.key >= today }
            .map { entry -> HomeworkDay in
                HomeworkDay(day: entry.key, items: entry.value.sorted(by: homeworkOrder))
            }
            .sorted { $0.day < $1.day }
    }

    private static func homeworkOrder(_ lhs: WatchHomework, _ rhs: WatchHomework) -> Bool {
        if lhs.done != rhs.done {
            return !lhs.done
        }
        if lhs.subject != rhs.subject {
            return lhs.subject.localizedCaseInsensitiveCompare(rhs.subject) == .orderedAscending
        }
        return lhs.id < rhs.id
    }
}
