// __tests__/App.test.tsx: the first screen, rendered with no phone and no browser.
import { render, screen } from "@testing-library/react-native";
import App from "../App";

test("the first screen shows this week's total", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(<App />);
  expect(screen.getByRole("heading")).toHaveTextContent("Study planner");
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
