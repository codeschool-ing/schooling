// __tests__/place.test.tsx: the switch asks for location when it is turned on, stays off if refused, and
// a session marked done while it is on is logged with a rounded place.
import { NavigationContainer } from "@react-navigation/native";
import * as Location from "expo-location";
import { fireEvent, render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { rounded } from "../src/place";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
jest.mock("expo-location", () => ({
  Accuracy: { Low: 2 },
  requestForegroundPermissionsAsync: jest.fn(),
  getCurrentPositionAsync: jest.fn(),
}));
const location = jest.mocked(Location);
const answer = (granted: boolean) =>
  ({ granted, canAskAgain: true, status: granted ? "granted" : "denied", expires: "never" }) as Location.LocationPermissionResponse;

beforeEach(() => jest.clearAllMocks());

test("two decimal places, and no more", () => {
  expect(rounded(-23.561414, -46.655881)).toEqual({ lat: -23.56, lng: -46.66 });
});

async function openWeek() {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
}

test("refused, the switch stays off and says what that means", async () => {
  location.requestForegroundPermissionsAsync.mockResolvedValue(answer(false));
  await openWeek();
  await fireEvent(screen.getByRole("switch", { name: "Note where I study" }), "valueChange", true);
  expect(screen.getByRole("switch", { name: "Note where I study" })).toHaveProp("value", false);
  expect(screen.getByRole("alert")).toHaveTextContent(/logged without a place/);
});

test("allowed, a session is logged with where it was done", async () => {
  location.requestForegroundPermissionsAsync.mockResolvedValue(answer(true));
  location.getCurrentPositionAsync.mockResolvedValue({
    coords: { latitude: -23.561414, longitude: -46.655881, altitude: null, accuracy: 900, altitudeAccuracy: null, heading: null, speed: null },
    timestamp: 0,
  });
  await openWeek();
  await fireEvent(screen.getByRole("switch", { name: "Note where I study" }), "valueChange", true);
  await fireEvent.press(screen.getByRole("button", { name: "Mark 20 min on 2026-10-21 done" }));
  expect(await screen.findByText("Studied at -23.56, -46.66 (1)")).toBeOnTheScreen();
  expect(location.getCurrentPositionAsync).toHaveBeenCalledWith({ accuracy: Location.Accuracy.Low });
});
