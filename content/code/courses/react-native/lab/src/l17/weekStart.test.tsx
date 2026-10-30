// __tests__/weekStart.test.tsx: the Courses tab says what the phone's calendar answered.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("the note names the phone's first day of the week", async () => {
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  expect(screen.getByText(/starts the week on Sunday;/)).toBeOnTheScreen();
});
