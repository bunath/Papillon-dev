import type { Homework } from "@/services/shared/homework";
import {
  type CourseDay,
  CourseStatus,
  CourseType,
} from "@/services/shared/timetable";
import { formatHTML } from "@/utils/format/html";

/**
 * What the iPhone sends to the Apple Watch app. The Swift side of this contract
 * is `targets/watch/Models.swift`: change one, change the other.
 *
 * Every timestamp is in milliseconds since the Unix epoch.
 */
export interface WatchCourse {
  id: string;
  subject: string;
  color?: string;
  room?: string;
  teacher?: string;
  start: number;
  end: number;
  canceled: boolean;
  info?: string;
}

export interface WatchHomework {
  id: string;
  subject: string;
  color?: string;
  content: string;
  due: number;
  done: boolean;
  evaluation: boolean;
}

export interface WatchPayload {
  version: number;
  sentAt: number;
  courses: WatchCourse[];
  homework: WatchHomework[];
}

export interface WatchPayloadInput {
  now: Date;
  courseDays: CourseDay[];
  homework: Homework[];
  /** Ids of the services of the account on screen. */
  services: string[];
  subjectName: (subject: string) => string;
  subjectColor: (subject: string) => string;
}

export const WATCH_PAYLOAD_VERSION = 1;

// The watch has a small screen and the payload travels as one message, so both
// windows and lists are kept short.
export const COURSE_WINDOW_DAYS = 7;
export const HOMEWORK_WINDOW_DAYS = 14;
const MAX_COURSES = 80;
const MAX_HOMEWORK = 50;
const MAX_CONTENT_LENGTH = 400;
const MAX_INFO_LENGTH = 40;

const startOfDay = (date: Date) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate());

// Built from the calendar fields rather than by adding 24 hours, which would
// land an hour off across a daylight saving change.
const addDays = (date: Date, days: number) =>
  new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);

const isValidDate = (date: unknown): date is Date =>
  date instanceof Date && Number.isFinite(date.getTime());

// Counts code points, so an emoji is never cut in half: a lone surrogate would
// make the JSON unreadable on the other side.
const truncate = (text: string, max: number) => {
  const characters = Array.from(text);
  if (characters.length <= max) {
    return text;
  }
  const kept = characters
    .slice(0, max - 1)
    .join("")
    .trimEnd();
  return `${kept}…`;
};

const belongsToAccount = (createdByAccount: string, services: string[]) =>
  services.includes(createdByAccount) || createdByAccount.startsWith("ical_");

function mapCourses(input: WatchPayloadInput, from: Date): WatchCourse[] {
  const until = addDays(from, COURSE_WINDOW_DAYS).getTime();
  const seen = new Set<string>();

  return input.courseDays
    .flatMap(day => day.courses)
    .filter(
      course =>
        isValidDate(course.from) &&
        isValidDate(course.to) &&
        course.type !== CourseType.VACATION &&
        belongsToAccount(course.createdByAccount, input.services) &&
        course.to.getTime() > from.getTime() &&
        course.from.getTime() < until
    )
    .sort(
      (a, b) =>
        a.from.getTime() - b.from.getTime() || a.to.getTime() - b.to.getTime()
    )
    .filter(course => {
      // The same course can come from two weeks' queries; the watch lists rows
      // by id and start time, so a duplicate would be drawn twice.
      const key = `${course.id}#${course.from.getTime()}`;
      if (seen.has(key)) {
        return false;
      }
      seen.add(key);
      return true;
    })
    .slice(0, MAX_COURSES)
    .map(course => ({
      id: course.id,
      subject: input.subjectName(course.subject),
      color: input.subjectColor(course.subject),
      room: course.room || undefined,
      teacher: course.teacher || undefined,
      start: course.from.getTime(),
      end: course.to.getTime(),
      canceled: course.status === CourseStatus.CANCELED,
      info: course.customStatus
        ? truncate(course.customStatus, MAX_INFO_LENGTH)
        : undefined,
    }));
}

function mapHomework(input: WatchPayloadInput, from: Date): WatchHomework[] {
  const until = addDays(from, HOMEWORK_WINDOW_DAYS).getTime();

  return input.homework
    .filter(
      item =>
        isValidDate(item.dueDate) &&
        input.services.includes(item.createdByAccount) &&
        item.dueDate.getTime() >= from.getTime() &&
        item.dueDate.getTime() < until
    )
    .sort((a, b) => a.dueDate.getTime() - b.dueDate.getTime())
    .slice(0, MAX_HOMEWORK)
    .map(item => ({
      id: item.id,
      subject: input.subjectName(item.subject),
      color: input.subjectColor(item.subject),
      content: truncate(formatHTML(item.content ?? ""), MAX_CONTENT_LENGTH),
      due: item.dueDate.getTime(),
      done: item.isDone,
      evaluation: item.evaluation,
    }));
}

/**
 * Picks what the watch needs out of what the phone already has: the courses of
 * the coming week and the homework due in the coming two, for the account on
 * screen, with subject names and colors as the phone shows them.
 */
export function buildWatchPayload(input: WatchPayloadInput): WatchPayload {
  const from = startOfDay(input.now);

  return {
    version: WATCH_PAYLOAD_VERSION,
    sentAt: input.now.getTime(),
    courses: mapCourses(input, from),
    homework: mapHomework(input, from),
  };
}

/**
 * Identifies a payload by its content alone, so a sync that would tell the
 * watch nothing new can be skipped.
 */
export const payloadFingerprint = (payload: WatchPayload) =>
  JSON.stringify({ ...payload, sentAt: 0 });
