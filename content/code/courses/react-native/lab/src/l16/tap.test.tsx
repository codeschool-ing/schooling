// __tests__/tap.test.tsx: tapping a reminder opens the course it names, through the same addresses as a link.
import { NavigationContainer } from "@react-navigation/native";
import * as Notifications from "expo-notifications";
import { act, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("a tapped reminder opens its course", async () => {
  await render(withPlan(<NavigationContainer linking={linking}><RootNavigator /></NavigationContainer>));
  const [[onTap]] = jest.mocked(Notifications.addNotificationResponseReceivedListener).mock.calls;
  await act(async () => {
    onTap({ notification: { request: { content: { data: { url: "planner://course/guitar" } } } } } as never);
  });
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-21", "2026-10-28"]);
});
