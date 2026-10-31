// __tests__/SessionList.test.tsx: sessions under their days, and an empty course.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { groupByDate, SessionList } from "../src/SessionList";

const spanish = data.sessions.filter((s) => s.course === "spanish");

test("sessions are grouped by day, in date order", () => {
  expect(groupByDate(spanish).map((g) => [g.title, g.data.length])).toEqual([
    ["2026-10-19", 1],
    ["2026-10-22", 1],
  ]);
});

test("each day is a heading, and each session a line under it", async () => {
  await render(<SessionList sessions={spanish} />);
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-19", "2026-10-22"]);
  expect(screen.getByText("30 min, done")).toBeOnTheScreen();
});

test("a course with no sessions says so", async () => {
  await render(<SessionList sessions={[]} />);
  expect(screen.getByText("No sessions yet.")).toBeOnTheScreen();
});
