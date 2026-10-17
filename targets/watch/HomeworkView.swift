import SwiftUI

struct HomeworkView: View {
    @EnvironmentObject private var store: WatchStore

    var body: some View {
        NavigationStack {
            TimelineView(.everyMinute) { context in
                content(now: context.date)
            }
            .navigationTitle(Strings.homework)
        }
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if let payload = store.payload {
            let days = Schedule.homeworkDays(from: payload.homework, now: now)
            if days.isEmpty {
                Placeholder(
                    symbol: "checkmark.seal",
                    text: Strings.noHomework,
                    footnote: store.syncLabel
                )
            } else {
                HomeworkList(days: days, now: now, footer: store.syncLabel)
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

/// The scrolling homework list: one section per due day, soonest first.
/// Tapping a row opens the full text.
struct HomeworkList: View {
    let days: [HomeworkDay]
    let now: Date
    let footer: String?

    var body: some View {
        List {
            ForEach(days) { day in
                Section {
                    ForEach(day.items, id: \.uid) { item in
                        NavigationLink {
                            HomeworkDetail(item: item, now: now)
                        } label: {
                            HomeworkRow(item: item)
                        }
                        .listRowBackground(RowBackground(tint: Color(hex: item.color)))
                    }
                } header: {
                    Text(Strings.dueTitle(day.day, now: now))
                }
            }

            SyncFooter(label: footer)
        }
    }
}

struct HomeworkRow: View {
    let item: WatchHomework

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 5) {
                Text(item.subject)
                    .font(.headline)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if item.done {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            if !item.content.isEmpty {
                Text(item.content)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            if item.evaluation {
                Badge(text: Strings.evaluation, color: .orange)
            }
        }
        .opacity(item.done ? 0.5 : 1)
        .padding(.vertical, 2)
    }
}

/// The whole text of one homework. It scrolls with the Digital Crown.
struct HomeworkDetail: View {
    let item: WatchHomework
    let now: Date

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: item.color))
                        .frame(width: 10, height: 10)
                    Text(item.subject)
                        .font(.headline)
                }

                Text(Strings.dueTitle(item.dueDate, now: now))
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                HStack(spacing: 6) {
                    if item.evaluation {
                        Badge(text: Strings.evaluation, color: .orange)
                    }
                    if item.done {
                        Badge(text: Strings.done, color: .green)
                    }
                }

                Text(item.content.isEmpty ? Strings.noDetails : item.content)
                    .font(.footnote)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(Strings.homework)
    }
}
