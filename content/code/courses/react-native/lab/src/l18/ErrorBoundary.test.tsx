// __tests__/ErrorBoundary.test.tsx: a screen that throws is replaced by a way out, and the way out works.
import { fireEvent, render, screen } from "@testing-library/react-native";
import { Text } from "react-native";
import { ErrorBoundary } from "../src/ErrorBoundary";

let broken = true;
function Screen() {
  if (broken) throw new Error("the plan has no sessions");
  return <Text>The week</Text>;
}

test("a throw becomes a message and a button, and the button tries again", async () => {
  jest.spyOn(console, "error").mockImplementation(() => {}); // React and the boundary both report it
  await render(
    <ErrorBoundary>
      <Screen />
    </ErrorBoundary>,
  );
  expect(screen.getByRole("alert")).toHaveTextContent(/Something went wrong/);
  broken = false;
  await fireEvent.press(screen.getByRole("button", { name: "Try again" }));
  expect(screen.getByText("The week")).toBeOnTheScreen();
});
