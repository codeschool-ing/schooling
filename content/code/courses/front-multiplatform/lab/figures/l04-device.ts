// src/device.ts: what the planner asks of the device, through Capacitor's plugins.
import { Preferences } from "@capacitor/preferences";
import { Directory, Encoding, Filesystem } from "@capacitor/filesystem";
import { LocalNotifications } from "@capacitor/local-notifications";
import { Geolocation } from "@capacitor/geolocation";
import { Camera } from "@capacitor/camera";
import type { Plan, Session } from "./planner";

export async function loadPlan(): Promise<Plan | null> {
  const { value } = await Preferences.get({ key: "plan" });
  return value === null ? null : JSON.parse(value);
}

export async function savePlan(plan: Plan): Promise<void> {
  await Preferences.set({ key: "plan", value: JSON.stringify(plan) });
}

export async function exportPlan(plan: Plan): Promise<string> {
  const file = { path: "planner-export.json", directory: Directory.Data, encoding: Encoding.UTF8 };
  await Filesystem.writeFile({ ...file, data: JSON.stringify(plan) });
  const back = await Filesystem.readFile(file);
  return `exported ${String(back.data).length} characters to ${file.path}`;
}

export async function remind(session: Session, course: string): Promise<string> {
  const { display } = await LocalNotifications.requestPermissions();
  if (display !== "granted") return `notifications are ${display}`;
  const at = new Date(`${session.date}T08:00:00`);
  await LocalNotifications.schedule({
    notifications: [{ id: Number(session.id.slice(1)), title: course, body: `${session.minutes} minutes today`, schedule: { at } }],
  });
  return `reminder at ${at.toLocaleString("en-GB")}`;
}

export async function whereAmI(): Promise<string> {
  const { coords } = await Geolocation.getCurrentPosition();
  return `studying at ${coords.latitude.toFixed(3)}, ${coords.longitude.toFixed(3)}`;
}

export async function photoOfNotes(): Promise<string> {
  const photo = await Camera.takePhoto({ quality: 80, webUseInput: true });
  const image = await (await fetch(photo.webPath!)).blob();
  return `a photo, ${image.type}, ${image.size} bytes`;
}
