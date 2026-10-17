import { useEffect } from "react";
import { AppState } from "react-native";

import { getDatabaseInstance } from "@/database/DatabaseProvider";
import {
  getHomeworksFromCache,
  getWeekNumberFromDate,
} from "@/database/useHomework";
import { getCoursesFromCache } from "@/database/useTimetable";
import {
  getWatchStatus,
  sendToWatch,
  watchIsSupported,
} from "@/modules/papillon-watch";
import { useAccountStore } from "@/stores/account";
import { warn } from "@/utils/logger/logger";
import { getSubjectColor } from "@/utils/subjects/colors";
import { getSubjectName } from "@/utils/subjects/name";

import {
  buildWatchPayload,
  payloadFingerprint,
  type WatchPayload,
} from "./payload";

// The database tells us when a sync wrote something; this is only the safety
// net, and what moves the window forward when the day changes.
const REFRESH_INTERVAL_MS = 5 * 60 * 1000;
// A sync writes many rows in a row: wait for it to settle before reading.
const CHANGE_DEBOUNCE_MS = 2000;
const FIRST_SYNC_DELAY_MS = 3000;

async function readPayload(
  services: string[],
  now: Date
): Promise<WatchPayload> {
  // getWeekNumberFromDate and the week ranges disagree by up to a week on which
  // day a week starts, so read one week either side. Numbers past the end of
  // the year simply spill into January.
  const week = getWeekNumberFromDate(now);
  const weeks = [week - 1, week, week + 1, week + 2];

  const [courseDays, homeworkByWeek] = await Promise.all([
    getCoursesFromCache(weeks, now.getFullYear()),
    Promise.all(weeks.map(weekNumber => getHomeworksFromCache(weekNumber))),
  ]);

  return buildWatchPayload({
    now,
    courseDays,
    homework: homeworkByWeek.flat(),
    services,
    subjectName: getSubjectName,
    subjectColor: getSubjectColor,
  });
}

/**
 * Keeps the Apple Watch app up to date with the timetable and homework.
 *
 * The payload is rebuilt when the database changes, when the app comes back to
 * the foreground or goes to the background, and every few minutes, and only
 * sent when it differs from the last one that went out.
 */
function useSync(): void {
  // A string rather than an array: the component only re-renders, and the
  // effect below only restarts, when the services of the account really change.
  const servicesKey = useAccountStore(state => {
    const account = state.accounts.find(
      item => item.id === state.lastUsedAccount
    );
    return (account?.services ?? []).map(service => service.id).join("|");
  });

  useEffect(() => {
    const services = servicesKey ? servicesKey.split("|") : [];
    let cancelled = false;
    let running = false;
    let runAgain = false;
    let timer: ReturnType<typeof setTimeout> | null = null;
    let lastSent: string | null = null;

    const sync = async () => {
      if (running) {
        runAgain = true;
        return;
      }
      running = true;
      try {
        // No watch, or no Papillon on it: nothing to read from the database.
        // Before the session is up the answer is unknown, so go ahead: the
        // native side holds the payload until it can be delivered.
        const status = await getWatchStatus();
        if (status.activated && !(status.paired && status.installed)) {
          return;
        }

        const now = new Date();
        const payload = await readPayload(services, now);
        const fingerprint = payloadFingerprint(payload);
        if (!cancelled && fingerprint !== lastSent) {
          if (await sendToWatch(JSON.stringify(payload))) {
            lastSent = fingerprint;
          }
        }
      } catch (error) {
        warn(`Watch sync failed: ${error}`);
      } finally {
        running = false;
        if (runAgain && !cancelled) {
          runAgain = false;
          schedule(CHANGE_DEBOUNCE_MS);
        }
      }
    };

    const schedule = (delay: number) => {
      if (timer) {
        clearTimeout(timer);
      }
      timer = setTimeout(() => {
        timer = null;
        void sync();
      }, delay);
    };

    const changes = getDatabaseInstance()
      .withChangesForTables(["courses", "homework"])
      .subscribe(() => schedule(CHANGE_DEBOUNCE_MS));
    const appState = AppState.addEventListener("change", state => {
      // Leaving the app is the last chance to hand over fresh data.
      schedule(state === "active" ? CHANGE_DEBOUNCE_MS / 4 : 0);
    });
    const interval = setInterval(() => schedule(0), REFRESH_INTERVAL_MS);
    schedule(FIRST_SYNC_DELAY_MS);

    return () => {
      cancelled = true;
      if (timer) {
        clearTimeout(timer);
      }
      clearInterval(interval);
      changes.unsubscribe();
      appState.remove();
    };
  }, [servicesKey]);
}

export const useWatchSync = watchIsSupported ? useSync : (): void => undefined;
