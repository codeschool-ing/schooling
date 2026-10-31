// __tests__/done.test.tsx: marking done shows at once, reaches the server, and is undone if the server refuses.
import { NavigationContainer } from "@react-navigation/native";
import { onlineManager } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
// What the server holds after the press: the same plan, with s3 done.
beforeEach(() => {
  jest.clearAllMocks();
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
});
const markGuitar = { name: "Mark 20 min on 2026-10-21 done" };

async function openWeekAndMark() {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
  await fireEvent.press(screen.getByRole("button", markGuitar));
  await fireEvent.press(screen.getByText("Courses"));
}

test("the total moves at once, and the server is told", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  await waitFor(() => expect(sendDone).toHaveBeenCalledWith("s3", expect.anything()));
});

test("a refusal puts the total back", async () => {
  jest.mocked(sendDone).mockRejectedValue(new Error("POST /sessions/s3/done answered 500"));
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data)); // the server did not change
  await openWeekAndMark();
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});

test("offline, the request waits; online again, it is sent", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  onlineManager.setOnline(false);
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  expect(sendDone).not.toHaveBeenCalled();
  onlineManager.setOnline(true);
  await waitFor(() => expect(sendDone).toHaveBeenCalledTimes(1));
});
