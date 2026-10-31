// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { fireEvent, render, screen } from "@testing-library/react-native";
import type { ReactElement } from "react";
import { SafeAreaProvider } from "react-native-safe-area-context";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;
const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };
const inPhone = (ui: ReactElement) => <SafeAreaProvider initialMetrics={phone}>{ui}</SafeAreaProvider>;

test("every course is a button named for what it holds", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(inPhone(<PlanScreen plan={plan} today="2026-10-21" />));
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
