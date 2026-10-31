// __tests__/WeekBar.test.tsx: the bar's value, which is what a screen reader hears.
// How it moves is measured in the browser, where the animation really runs.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("the bar says its value, before and after a session is done", async () => {
  const view = await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
  await view.rerender(<WeekBar done={95} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ now: 95 });
});
