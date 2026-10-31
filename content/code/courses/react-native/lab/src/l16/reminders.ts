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
