// __tests__/reminders.test.ts: which reminders a plan asks for, and what reaches the phone's scheduler.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Notifications from "expo-notifications";
import { Platform } from "react-native";
import data from "../src/courses.json";
import { remindersFor, scheduleReminders, setReminders } from "../src/reminders";

const notifications = jest.mocked(Notifications);
const noon = new Date("2026-10-21T12:00:00"); // local time, as the phone would have it

beforeEach(() => jest.clearAllMocks());

test("one reminder per session not done, at six in the evening of its day", () => {
  const reminders = remindersFor(data, noon);
  expect(reminders.map((r) => r.id)).toEqual(["s3", "s4", "s5", "s6"]);
  expect(reminders[0]).toMatchObject({ title: "Guitar: 20 min today", url: "planner://course/guitar" });
  expect([reminders[0].at.getDate(), reminders[0].at.getHours()]).toEqual([21, 18]);
});

test("a reminder whose time has passed is not asked for", () => {
  expect(remindersFor(data, new Date("2026-10-21T19:00:00")).map((r) => r.id)).toEqual(["s4", "s5", "s6"]);
});

test("scheduling replaces everything that was scheduled before", async () => {
  await scheduleReminders(data, noon);
  expect(notifications.cancelAllScheduledNotificationsAsync).toHaveBeenCalledTimes(1);
  expect(notifications.scheduleNotificationAsync).toHaveBeenCalledTimes(4);
  expect(notifications.scheduleNotificationAsync.mock.calls[0][0]).toMatchObject({
    identifier: "s3",
    content: { data: { url: "planner://course/guitar" } },
    trigger: { type: "date", channelId: "reminders" },
  });
});

test("refused, reminders stay off", async () => {
  notifications.requestPermissionsAsync.mockResolvedValue({ granted: false } as Notifications.NotificationPermissionsStatus);
  expect(await setReminders(true)).toBe("refused");
  expect(await AsyncStorage.getItem("reminders")).toBeNull();
});

test("on Android, the channel exists before the question is asked", async () => {
  jest.replaceProperty(Platform, "OS", "android");
  notifications.requestPermissionsAsync.mockResolvedValue({ granted: true } as Notifications.NotificationPermissionsStatus);
  expect(await setReminders(true)).toBe("on");
  const channel = notifications.setNotificationChannelAsync.mock.invocationCallOrder[0];
  const question = notifications.requestPermissionsAsync.mock.invocationCallOrder[0];
  expect(channel).toBeLessThan(question);
});
