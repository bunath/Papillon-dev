import SwiftUI

struct TimetableView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        NavigationStack {
            // Redrawn every minute, so "now" and "finished" follow the clock
            // even when the phone has nothing new to send.
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .navigationTitle(Strings.timetable)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let payload = store.payload {
            let days = Schedule.days(from: payload.courses, now: now)
            if days.isEmpty {
                Placeholder(
                    symbol: "checkmark.circle",
                    text: Strings.noCourses,
                    footnote: store.syncLabel
                )
            } else {
                CourseList(days: days, now: now, footer: store.syncLabel)
            }
        } else {
            Placeholder(
                symbol: "iphone",
                text: Strings.waitingForPhone,
                footnote: nil
            )
        }
    }
}

/// The scrolling timetable: one section per day, today first.
struct CourseList: View {
    let days: [CourseDay]
    let now: Date
    let footer: String?

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(days) { day in
                    Section {
                        ForEach(day.courses, id: \.uid) { course in
                            CourseRow(course: course, now: now)
                        }
                    } header: {
                        Text(Strings.dayTitle(day.day, now: now))
                    }
                }

                SyncFooter(label: footer)
            }
            .onAppear {
                // Open on what matters: the course under way, or the next one.
                guard let focus = Schedule.focus(in: days, now: now) else {
                    return
                }
                DispatchQueue.main.async {
                    proxy.scrollTo(focus.uid, anchor: .top)
                }
            }
        }
    }
}

struct CourseRow: View {
    let course: WatchCourse
    let now: Date

    private var state: CourseState { Schedule.state(of: course, now: now) }
    private var tint: Color { Color(hex: course.color) }

    private var timeRange: String {
        let start = course.startDate.formatted(date: .omitted, time: .shortened)
        let end = course.endDate.formatted(date: .omitted, time: .shortened)
        return "\(start) – \(end)"
    }

    /// Room and teacher, whichever the school provides.
    private var details: String? {
        let parts = [course.room, course.teacher]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(tint)
                .frame(width: 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(timeRange)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(course.subject)
                    .font(.headline)
                    .strikethrough(course.canceled)
                    .lineLimit(2)

                if let details = details {
                    Text(details)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if course.canceled {
                    Badge(text: Strings.cancelled, color: .red)
                } else if state == .ongoing {
                    Badge(text: Strings.ongoing, color: tint)
                } else if let info = course.info, !info.isEmpty {
                    Badge(text: info, color: .orange)
                }
            }
        }
        .opacity(state == .finished ? 0.45 : 1)
        .listRowBackground(RowBackground(tint: tint, emphasised: state == .ongoing))
    }
}
