import Foundation

/// What the iPhone sends to the watch.
///
/// Every timestamp is a number of milliseconds since the Unix epoch, which is
/// what JavaScript's `Date.getTime()` returns, so the phone converts nothing.
/// The TypeScript side of this contract is `utils/watch/payload.ts`.
struct WatchPayload: Codable, Equatable {
    var version: Int
    var sentAt: Double
    var courses: [WatchCourse]
    var homework: [WatchHomework]

    var sentDate: Date { Date(timeIntervalSince1970: sentAt / 1000) }

    enum CodingKeys: String, CodingKey {
        case version, sentAt, courses, homework
    }

    init(
        version: Int = 1,
        sentAt: Double = 0,
        courses: [WatchCourse] = [],
        homework: [WatchHomework] = []
    ) {
        self.version = version
        self.sentAt = sentAt
        self.courses = courses
        self.homework = homework
    }

    /// A single malformed course or homework is dropped instead of making the
    /// whole payload unreadable, so one bad row never blanks the watch.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = (try? container.decode(Int.self, forKey: .version)) ?? 1
        sentAt = (try? container.decode(Double.self, forKey: .sentAt)) ?? 0
        courses = WatchPayload.decodeLossy(container, .courses)
        homework = WatchPayload.decodeLossy(container, .homework)
    }

    private static func decodeLossy<T: Decodable>(
        _ container: KeyedDecodingContainer<CodingKeys>,
        _ key: CodingKeys
    ) -> [T] {
        let items = (try? container.decode([Lossy<T>].self, forKey: key)) ?? []
        return items.compactMap { $0.value }
    }
}

private struct Lossy<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

struct WatchCourse: Codable, Equatable {
    var id: String
    var subject: String
    var color: String?
    var room: String?
    var teacher: String?
    var start: Double
    var end: Double
    var canceled: Bool
    var info: String?

    var startDate: Date { Date(timeIntervalSince1970: start / 1000) }
    var endDate: Date { Date(timeIntervalSince1970: end / 1000) }

    /// Two courses can share an id (a recurring calendar event, say) but not an
    /// id and a start time, so this is what lists identify rows by.
    var uid: String { "\(id)#\(String(format: "%.0f", start))" }
}

struct WatchHomework: Codable, Equatable {
    var id: String
    var subject: String
    var color: String?
    var content: String
    var due: Double
    var done: Bool
    var evaluation: Bool

    var dueDate: Date { Date(timeIntervalSince1970: due / 1000) }
    var uid: String { "\(id)#\(String(format: "%.0f", due))" }
}
