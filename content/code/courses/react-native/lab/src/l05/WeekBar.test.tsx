// __tests__/WeekBar.test.tsx: the bar's two parts grow in the ratio of done to left.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("done and left share the bar by flex", async () => {
  await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByTestId("week-done")).toHaveStyle({ flex: 75 });
  expect(screen.getByTestId("week-left")).toHaveStyle({ flex: 50 });
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
});
