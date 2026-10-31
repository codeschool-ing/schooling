// __tests__/failure.test.tsx: a server that is down is a sentence and a button, not a blank screen.
import { render, screen } from "@testing-library/react-native";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api");

test("the plan cannot be loaded", async () => {
  jest.mocked(fetchPlan).mockRejectedValue(new Error("GET /plan answered 503"));
  await render(<App />);
  expect(await screen.findByText("The plan could not be loaded: GET /plan answered 503", {}, { timeout: 10_000 })).toBeOnTheScreen();
  expect(screen.getByRole("button", { name: "Try again" })).toBeOnTheScreen();
}, 15_000);
