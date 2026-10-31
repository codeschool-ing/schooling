---
title: Cada resposta, num teste
version: 1
---

**Um diálogo de permissão não pode ser apertado no Jest, e não precisa.** O que a tela faz é decidido pela
resposta, então o teste troca o seletor por um substituto e entrega à tela cada resposta por vez. Salve o
`__tests__/NotesPhoto.test.tsx`:

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

O `jest.mock` com uma fábrica troca o módulo inteiro por três funções que não fazem nada até um teste dizer
o que devolvem. O `jest.mocked` lhes devolve os tipos, então o `mockResolvedValue` é conferido contra o que
a função de verdade devolve. **As respostas são montadas com os campos de verdade**, `granted`,
`canAskAgain`, `status` e `expires`, então o teste da recusa definitiva usa o mesmo objeto que um celular
entregaria.

O `keepPhoto` também é trocado, por uma função que devolve o endereço que recebeu. Esse é código nosso, e
trocá-lo é uma escolha: o trabalho dele é o sistema de arquivos do celular, que o Jest não tem, e a tela só
precisa de um endereço de volta. A cópia em si está na seção anterior, marcada como não executada.

Agora o projeto compila. Confira e rode os testes novos:

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

**Cinco respostas, cinco comportamentos**: uma foto mostrada, um cancelamento ignorado, uma primeira recusa
explicada sem a câmera abrir, uma recusa definitiva mandando a pessoa aos Ajustes, e um sim. O teste da
primeira recusa também confere o que não pode acontecer: nenhum botão *Open Settings*, e nenhuma câmera.
