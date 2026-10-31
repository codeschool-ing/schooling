---
title: Sair, com algo digitado
version: 1
---

**O formulário pergunta antes de jogar fora o que a pessoa digitou**, com o listener `beforeRemove` que a aula 8
esboçou, agora de verdade. Ele roda seja qual for o jeito de sair: o botão de voltar do cabeçalho, o deslizar
do iOS, a ação de voltar do Android, ou código chamando `goBack`.

Dois refinamentos em relação ao esboço, os dois visíveis na tela:

- **Nada digitado, nada perguntado.** O `dirty` só é verdadeiro quando um campo tem algo.
- **Depois de salvar com sucesso, nada perguntado.** A tela define `saved.current = true` antes de voltar. É uma
  ref, e não estado, de propósito: o salvamento volta na mesma função, antes de o React ter renderizado um valor
  novo de estado, e um listener lendo estado velho perguntaria *Discard this session?* sobre uma sessão que
  acabou de ser salva.

Na web, o `Alert.alert` do `react-native-web` não mostra nada, então o listener bloquearia a navegação sem
pergunta nenhuma. Um app que publica o build web usa o `window.confirm` ali, escolhido com `Platform.OS`, que é
uma diferença do tipo da aula 6; o build web do planner é um substituto para este curso, e os testes abaixo
exercitam o comportamento dos celulares.

## Quatro testes

Salve isto como `__tests__/AddSession.test.tsx`:

```tsx
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
```

O `createNavigationContainerRef` dá ao teste um acesso à navegação, para perguntar qual é a tela atual e chamar
o `goBack` do jeito que o sistema chamaria. O `jest.spyOn(Alert, "alert")` registra a pergunta em vez de
mostrá-la. O plano é buscado de novo depois de salvar, então cada teste também diz o que o servidor
responderia.

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest AddSession --forceExit
PASS __tests__/AddSession.test.tsx
  ✓ wrong entries are refused with a sentence each, and nothing is sent (315 ms)
  ✓ a good session is sent as numbers, and the form closes (115 ms)
  ✓ a refusal from the server is shown, and the form stays (95 ms)
  ✓ leaving with something typed asks first (87 ms)

Test Suites: 1 passed, 1 total
Tests:       4 passed, 4 total
Snapshots:   0 total
Time:        1.645 s, estimated 7 s
Ran all test suites matching AddSession.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

O primeiro teste confere as duas frases, palavra por palavra, e que **nada foi enviado**; o segundo, que os
minutos vão como número, `25`, e não `"25"`; o terceiro, que uma recusa aparece e o formulário fica, com o que
foi digitado; o quarto, que sair pergunta.
