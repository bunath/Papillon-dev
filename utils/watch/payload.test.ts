import type { Homework } from "@/services/shared/homework";
import {
  type Course,
  type CourseDay,
  CourseStatus,
  CourseType,
} from "@/services/shared/timetable";

import {
  buildWatchPayload,
  HOMEWORK_WINDOW_DAYS,
  payloadFingerprint,
} from "./payload";

// Friday 16 October 2026, 09:30 in the machine's timezone.
const NOW = new Date(2026, 9, 16, 9, 30);

const at = (dayOffset: number, hour: number, minute = 0) =>
  new Date(2026, 9, 16 + dayOffset, hour, minute);

const course = (
  id: string,
  from: Date,
  to: Date,
  extra: Partial<Course> = {}
): Course => ({
  id,
  subject: "Maths",
  type: CourseType.LESSON,
  from,
  to,
  createdByAccount: "service-1",
  ...extra,
});

const homework = (
  id: string,
  dueDate: Date,
  extra: Partial<Homework> = {}
): Homework => ({
  id,
  subject: "Maths",
  content: "Exercice 4",
  dueDate,
  isDone: false,
  attachments: [],
  evaluation: false,
  custom: false,
  createdByAccount: "service-1",
  ...extra,
});

const day = (courses: Course[]): CourseDay => ({
  date: new Date(2026, 9, 16),
  courses,
});

const build = (courseDays: CourseDay[], homeworks: Homework[] = []) =>
  buildWatchPayload({
    now: NOW,
    courseDays,
    homework: homeworks,
    services: ["service-1"],
    subjectName: subject => subject.toUpperCase(),
    subjectColor: () => "#112233",
  });

test("courses of the coming week come in start order, named and colored as on the phone", () => {
  const payload = build([
    day([
      course("b", at(0, 10), at(0, 11)),
      course("a", at(0, 8), at(0, 9)),
      course("edge", at(6, 20), at(6, 21)),
      course("too-far", at(7, 8), at(7, 9)),
      course("yesterday", at(-1, 8), at(-1, 9)),
    ]),
  ]);

  expect(payload.courses.map(item => item.id)).toEqual(["a", "b", "edge"]);
  expect(payload.courses[0]).toMatchObject({
    subject: "MATHS",
    color: "#112233",
    start: at(0, 8).getTime(),
    end: at(0, 9).getTime(),
    canceled: false,
  });
  expect(payload.sentAt).toBe(NOW.getTime());
});

test("a cancelled course is flagged and keeps its status text", () => {
  const payload = build([
    day([
      course("x", at(0, 10), at(0, 11), {
        status: CourseStatus.CANCELED,
        customStatus: "Prof absent",
      }),
    ]),
  ]);

  expect(payload.courses[0]).toMatchObject({
    canceled: true,
    info: "Prof absent",
  });
});

test("vacations, other accounts, duplicates and broken dates are left out, calendar events stay", () => {
  const payload = build([
    day([
      course("holiday", at(1, 0), at(1, 23), { type: CourseType.VACATION }),
      course("other", at(1, 8), at(1, 9), { createdByAccount: "service-2" }),
      course("ical", at(1, 9), at(1, 10), { createdByAccount: "ical_abc" }),
      course("dup", at(1, 10), at(1, 11)),
      course("dup", at(1, 10), at(1, 11)),
      course("broken", new Date(NaN), at(1, 12)),
    ]),
  ]);

  expect(payload.courses.map(item => item.id)).toEqual(["ical", "dup"]);
});

test("homework due within two weeks is kept, as plain text, with its flags", () => {
  const payload = build(
    [],
    [
      homework("late", at(-1, 8)),
      homework("soon", at(1, 8), {
        content: "<p>Lire <b>le chapitre 3</b></p>",
        isDone: true,
        evaluation: true,
      }),
      homework("later", at(5, 8)),
      homework("far", at(HOMEWORK_WINDOW_DAYS + 1, 8)),
      homework("other", at(2, 8), { createdByAccount: "service-2" }),
    ]
  );

  expect(payload.homework.map(item => item.id)).toEqual(["soon", "later"]);
  expect(payload.homework[0]).toMatchObject({
    subject: "MATHS",
    color: "#112233",
    content: "Lire le chapitre 3",
    due: at(1, 8).getTime(),
    done: true,
    evaluation: true,
  });
});

test("long text is cut at 400 characters without splitting an emoji", () => {
  const payload = build(
    [],
    [homework("h", at(1, 8), { content: "😀".repeat(500) })]
  );
  const { content } = payload.homework[0];

  expect(Array.from(content)).toHaveLength(400);
  expect(content.endsWith("…")).toBe(true);
});

test("the fingerprint ignores when the payload was sent, not what it holds", () => {
  const payload = build([day([course("a", at(0, 8), at(0, 9))])]);
  const later = { ...payload, sentAt: payload.sentAt + 60_000 };

  expect(payloadFingerprint(later)).toBe(payloadFingerprint(payload));
  expect(payloadFingerprint({ ...payload, courses: [] })).not.toBe(
    payloadFingerprint(payload)
  );
});
