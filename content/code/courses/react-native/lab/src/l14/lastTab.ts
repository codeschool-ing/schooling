// src/lastTab.ts: the tab the planner was last on, read synchronously, before the first frame.
import { createMMKV } from "react-native-mmkv";

const storage = createMMKV({ id: "planner" });

export function lastTab(): "Courses" | "Week" {
  return storage.getString("tab") === "Week" ? "Week" : "Courses";
}

export function rememberTab(tab: "Courses" | "Week") {
  storage.set("tab", tab);
}
