// __tests__/App.test.tsx: the app waits for the plan, and says so when it cannot have it.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api"); // no server in a test: each test says what the server answers

beforeEach(() => jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") }));

test("loading, then the plan", async () => {
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data));
  await render(<App />);
  expect(screen.getByRole("status")).toHaveTextContent("Loading the plan");
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
