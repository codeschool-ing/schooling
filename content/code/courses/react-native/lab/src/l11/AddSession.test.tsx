// __tests__/AddSession.test.tsx: the form refuses, saves, reports the server, and asks before discarding.
import { createNavigationContainerRef, NavigationContainer } from "@react-navigation/native";
import { act, fireEvent, render, screen } from "@testing-library/react-native";
import { Alert } from "react-native";
import data from "../src/courses.json";
import { createSession, fetchPlan } from "../src/api";
import { RootNavigator, type RootParams } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
const nav = createNavigationContainerRef<RootParams>();

async function openForm() {
  jest.clearAllMocks();
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data)); // what the plan is refetched as
  await render(withPlan(<NavigationContainer ref={nav}><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByRole("button", { name: /^Guitar/ }));
  await fireEvent.press(screen.getByRole("button", { name: "Add a session" }));
}

test("wrong entries are refused with a sentence each, and nothing is sent", async () => {
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "23/10/2026");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "300");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(screen.getAllByRole("alert").map((a) => a.props.children)).toEqual([
    "Write the date as YYYY-MM-DD, for example 2026-10-23.",
    "A session is between 5 and 240 minutes.",
  ]);
  expect(createSession).not.toHaveBeenCalled();
});

test("a good session is sent as numbers, and the form closes", async () => {
  jest.mocked(createSession).mockResolvedValue({ id: "s7", course: "guitar", date: "2026-10-23", minutes: 25, done: false });
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "2026-10-23");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(createSession).toHaveBeenCalledWith({ course: "guitar", date: "2026-10-23", minutes: 25 });
  expect(nav.getCurrentRoute()?.name).toBe("Course");
});

test("a refusal from the server is shown, and the form stays", async () => {
  jest.mocked(createSession).mockRejectedValue(new Error("POST /sessions answered 503"));
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Date"), "2026-10-23");
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await fireEvent.press(screen.getByRole("button", { name: "Save session" }));
  expect(await screen.findByText("The server refused it: POST /sessions answered 503")).toBeOnTheScreen();
  expect(nav.getCurrentRoute()?.name).toBe("AddSession");
});

test("leaving with something typed asks first", async () => {
  const ask = jest.spyOn(Alert, "alert");
  await openForm();
  await fireEvent.changeText(screen.getByLabelText("Minutes"), "25");
  await act(async () => nav.goBack());
  expect(ask).toHaveBeenCalledWith("Discard this session?", "What you typed will be lost.", expect.any(Array));
  expect(nav.getCurrentRoute()?.name).toBe("AddSession");
});
