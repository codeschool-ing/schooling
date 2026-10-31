// __tests__/bare-string.test.tsx: what happens to a string outside <Text>.
import { render } from "@testing-library/react-native";
import { View } from "react-native";

test("a string straight inside a View", async () => {
  await render(<View>This week</View>);
});
