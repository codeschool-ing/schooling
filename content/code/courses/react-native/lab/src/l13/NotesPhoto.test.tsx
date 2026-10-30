// __tests__/NotesPhoto.test.tsx: what the screen does with each answer the picker and the camera give.
// The picker is a stand-in, so each test decides the answer; nothing here opens a camera.
import * as ImagePicker from "expo-image-picker";
import { fireEvent, render, screen } from "@testing-library/react-native";
import { Linking } from "react-native";
import { NotesPhoto } from "../src/NotesPhoto";

jest.mock("expo-image-picker", () => ({
  launchImageLibraryAsync: jest.fn(),
  launchCameraAsync: jest.fn(),
  requestCameraPermissionsAsync: jest.fn(),
}));
jest.mock("../src/keepPhoto", () => ({ keepPhoto: (uri: string) => uri })); // a phone's files, not the screen's
const picker = jest.mocked(ImagePicker);
const photo = { canceled: false, assets: [{ uri: "file:///cache/notes.jpg", width: 1200, height: 900 }] };
const answer = (granted: boolean, canAskAgain: boolean) =>
  ({ granted, canAskAgain, status: granted ? "granted" : "denied", expires: "never" }) as ImagePicker.CameraPermissionResponse;

beforeEach(() => jest.clearAllMocks());

test("a chosen photo is shown", async () => {
  picker.launchImageLibraryAsync.mockResolvedValue(photo as ImagePicker.ImagePickerResult);
  await render(<NotesPhoto course="guitar" />);
  await fireEvent.press(screen.getByRole("button", { name: "Choose a photo" }));
  expect(screen.getByLabelText("Your photo of the notes").props.source).toEqual({ uri: "file:///cache/notes.jpg" });
});

test("cancelling the picker changes nothing", async () => {
  picker.launchImageLibraryAsync.mockResolvedValue({ canceled: true, assets: null });
  await render(<NotesPhoto course="guitar" />);
  await fireEvent.press(screen.getByRole("button", { name: "Choose a photo" }));
  expect(screen.queryByLabelText("Your photo of the notes")).toBeNull();
});

test("a camera refused once is explained, and not opened", async () => {
  picker.requestCameraPermissionsAsync.mockResolvedValue(answer(false, true));
  await render(<NotesPhoto course="guitar" />);
  await fireEvent.press(screen.getByRole("button", { name: "Take a photo" }));
  expect(screen.getByRole("alert")).toHaveTextContent(/cannot take a photo/);
  expect(screen.queryByRole("button", { name: "Open Settings" })).toBeNull();
  expect(picker.launchCameraAsync).not.toHaveBeenCalled();
});

test("a camera refused for good sends the person to Settings", async () => {
  picker.requestCameraPermissionsAsync.mockResolvedValue(answer(false, false));
  const settings = jest.spyOn(Linking, "openSettings").mockResolvedValue(undefined);
  await render(<NotesPhoto course="guitar" />);
  await fireEvent.press(screen.getByRole("button", { name: "Take a photo" }));
  await fireEvent.press(screen.getByRole("button", { name: "Open Settings" }));
  expect(settings).toHaveBeenCalled();
});

test("a camera allowed takes the photo", async () => {
  picker.requestCameraPermissionsAsync.mockResolvedValue(answer(true, true));
  picker.launchCameraAsync.mockResolvedValue(photo as ImagePicker.ImagePickerResult);
  await render(<NotesPhoto course="guitar" />);
  await fireEvent.press(screen.getByRole("button", { name: "Take a photo" }));
  expect(screen.getByLabelText("Your photo of the notes")).toBeTruthy();
});
