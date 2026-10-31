---
title: Every answer, in a test
version: 1
---

**A permission dialog cannot be pressed in Jest, and it does not need to be.** What the screen does is
decided by the answer, so the test replaces the picker with a stand-in and hands the screen each answer
in turn. Save `__tests__/NotesPhoto.test.tsx`:

```tsx
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
```

`jest.mock` with a factory replaces the whole module with three functions that do nothing until a test
says what they return. `jest.mocked` gives them their types back, so `mockResolvedValue` is checked
against what the real function returns. **The answers are built with the real fields**, `granted`,
`canAskAgain`, `status` and `expires`, so a test of the final refusal is the same object a phone would
hand over.

`keepPhoto` is replaced as well, by a function that returns the address it was given. That one is our own
code, and replacing it is a choice: its job is the phone's file system, which Jest does not have, and the
screen only needs an address back. The copy itself is in the previous section, marked as not run.

Now the project compiles. Check it and run the new tests:

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest NotesPhoto --forceExit
PASS __tests__/NotesPhoto.test.tsx
  ✓ a chosen photo is shown (165 ms)
  ✓ cancelling the picker changes nothing (5 ms)
  ✓ a camera refused once is explained, and not opened (8 ms)
  ✓ a camera refused for good sends the person to Settings (8 ms)
  ✓ a camera allowed takes the photo (5 ms)

Test Suites: 1 passed, 1 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        0.753 s, estimated 1 s
Ran all test suites matching NotesPhoto.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**Five answers, five behaviours**: a photo shown, a cancel ignored, a first refusal explained without
the camera ever opening, a final refusal sending the person to Settings, and a yes. The test for the first
refusal also checks what must not happen: no *Open Settings* button, and no camera.
