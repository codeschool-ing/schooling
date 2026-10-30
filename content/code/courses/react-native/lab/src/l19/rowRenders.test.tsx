// __tests__/rowRenders.test.tsx: how many components render again when one session of fifty is marked
// done. Every row reads the theme once per render, so counting useTheme counts renders.
import { render } from "@testing-library/react-native";
import { markDone, type Session } from "../src/planner";
import { SessionList } from "../src/SessionList";
import { useTheme } from "../src/theme";

jest.mock("../src/theme", () => {
  const actual = jest.requireActual("../src/theme");
  return { ...actual, useTheme: jest.fn(actual.useTheme) };
});
const counted = jest.mocked(useTheme);

const sessions: Session[] = Array.from({ length: 50 }, (_, i) => ({
  id: `s${i}`,
  course: "guitar",
  date: `2026-11-${String(1 + (i % 28)).padStart(2, "0")}`,
  minutes: 20,
  done: false,
}));
const after = markDone({ courses: [], sessions }, "s1").sessions;

test("a callback made once", async () => {
  const onDone = () => {};
  const view = await render(<SessionList sessions={sessions} onDone={onDone} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={onDone} />);
  console.log("rendered again, with the same callback:", counted.mock.calls.length);
});

test("a callback made on every render", async () => {
  const view = await render(<SessionList sessions={sessions} onDone={() => {}} />);
  counted.mockClear();
  await view.rerender(<SessionList sessions={after} onDone={() => {}} />);
  console.log("rendered again, with a new callback:", counted.mock.calls.length);
});
