// __tests__/logged.test.tsx: a session the server agrees is done reaches the journal, and the week shows it.
import { NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");

test("the week shows what this phone has logged", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
  expect(await screen.findByText("Nothing logged on this phone yet")).toBeOnTheScreen();
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(await screen.findByText("Logged on this phone: Guitar 20 min")).toBeOnTheScreen();
});
