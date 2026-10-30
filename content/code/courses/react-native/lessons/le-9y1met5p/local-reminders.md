---
title: A reminder on the day of each session
version: 1
---

Everything about reminders is in one file. Save `src/reminders.ts`:

```ts
// src/reminders.ts: a reminder on the evening of every session still to do, scheduled on the phone
// itself, so it arrives with no server and no network.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import type { Plan } from "./planner";

const KEY = "reminders";
export const CHANNEL = "reminders";
export const REMIND_AT = 18; // a session has a date and no time, so its reminder comes at six in the evening

export type Reminder = { id: string; at: Date; title: string; url: string };

// Which reminders a plan asks for, from now on. No phone needed, so a test can ask it anything.
export function remindersFor(plan: Plan, now: Date): Reminder[] {
  return plan.sessions
    .filter((s) => !s.done)
    .map((s) => {
      const course = plan.courses.find((c) => c.id === s.course)?.name ?? s.course;
      const at = new Date(`${s.date}T${String(REMIND_AT).padStart(2, "0")}:00:00`); // the phone's local time
      return { id: s.id, at, title: `${course}: ${s.minutes} min today`, url: `planner://course/${s.course}` };
    })
    .filter((r) => r.at > now);
}

// Every call replaces what was scheduled, so a session done, added or moved never leaves a stale one.
export async function scheduleReminders(plan: Plan, now = new Date()) {
  await Notifications.cancelAllScheduledNotificationsAsync();
  for (const r of remindersFor(plan, now)) {
    await Notifications.scheduleNotificationAsync({
      identifier: r.id,
      content: { title: r.title, body: "Tap to open the course.", data: { url: r.url } },
      trigger: { type: Notifications.SchedulableTriggerInputTypes.DATE, date: r.at, channelId: CHANNEL },
    });
  }
}

export async function remindersOn() {
  return (await AsyncStorage.getItem(KEY)) === "on";
}

// Turning reminders on is the moment to ask. On Android 13 and later the dialog only appears once the
// app has a channel, so the channel comes first.
export async function setReminders(on: boolean): Promise<"on" | "off" | "refused"> {
  if (on) {
    if (Platform.OS === "android") {
      await Notifications.setNotificationChannelAsync(CHANNEL, {
        name: "Study reminders",
        importance: Notifications.AndroidImportance.DEFAULT,
      });
    }
    if (!(await Notifications.requestPermissionsAsync()).granted) return "refused";
  } else {
    await Notifications.cancelAllScheduledNotificationsAsync();
  }
  await AsyncStorage.setItem(KEY, on ? "on" : "off");
  return on ? "on" : "off";
}
```

- **`remindersFor` decides, and touches nothing.** It takes a plan and a time and returns the reminders
  that plan asks for: one per session not done, at six in the evening of its date, if that is still in the
  future. Because it schedules nothing, a test can ask it about any plan at any hour.
- **The date has no time zone on purpose.** `new Date("2026-10-21T18:00:00")` is six in the evening in
  the phone's own time zone, which is what a person means by "six in the evening". Written with a `Z` at
  the end, it would be six in Greenwich, and three in the afternoon in São Paulo.
- **`scheduleReminders` cancels everything first, then schedules.** The alternative, finding what changed
  and patching the schedule, has a bug in it for every way a plan can change. Each reminder's identifier
  is its session's id, so the schedule can always be read back and matched.
- **The reminder carries an address**, `planner://course/guitar`, in its `data`. A tap on it should open
  that course, and the handlers section does that.

The trigger is a `DATE`: one moment. There are triggers for intervals, for every day at a time, and for
calendar patterns too; a session is a one-off, so a date is the truth.
