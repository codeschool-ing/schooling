// __tests__/done.test.tsx: marking a session done on one screen changes the total on another.
import { fireEvent, render, screen } from "@testing-library/react-native";
import App from "../App";

test("done in the This week tab, counted in the Courses tab", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(<App />);
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  await fireEvent.press(screen.getByText("This week"));
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(screen.getByText("20 min, done")).toBeOnTheScreen();
  await fireEvent.press(screen.getByText("Courses"));
  expect(screen.getByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
});
