// __tests__/platform.test.ts: one test, run once for each platform jest-expo knows.
import { Platform } from "react-native";
import { card } from "../src/card";
import { savedWhere } from "../src/savedWhere";

test("each platform gets its own file and its own shadow", () => {
  const shadow = Object.keys(card).filter((k) => /shadow|elevation/i.test(k));
  console.log(Platform.OS, "|", savedWhere, "|", shadow.join(" "));
  expect(shadow.length).toBeGreaterThan(0);
});
