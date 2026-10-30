// __tests__/PlanScreen.test.tsx: the screen, read the way a screen reader reads it.
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { PlanScreen } from "../src/PlanScreen";
import type { Plan } from "../src/planner";

const plan: Plan = data;

test("every course is a button named for what it holds", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  expect(screen.getAllByRole("button")).toHaveLength(3);
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
});

test("pressing a course opens it", async () => {
  await render(<PlanScreen plan={plan} today="2026-10-21" />);
  await fireEvent.press(screen.getByRole("button", { name: /Guitar/ }));
  expect(screen.getByRole("status")).toHaveTextContent("Open: Guitar");
});
