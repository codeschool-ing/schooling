---
title: Uma mudança que aparece na hora e pode ser desfeita
version: 1
---

**Uma mutation é uma escrita.** O `useMutation` recebe a função que faz a requisição e três hooks que rodam em
volta dela, e o `useMarkDone` do `src/planState.tsx` usa os três:

| hook | quando | o que o planner faz |
|---|---|---|
| `onMutate` | antes da requisição | interrompe qualquer busca de `["plan"]` em curso, guarda o plano como estava, e escreve a mudança no cache **agora** |
| `onError` | se a requisição falha | põe de volta o plano que guardou |
| `onSettled` | depois de sucesso ou falha | invalida `["plan"]`, para a versão do próprio servidor ser buscada |

**Isto é uma atualização otimista**: a tela mostra a sessão feita antes de o servidor dizer qualquer coisa,
porque o servidor quase sempre concorda, e esperar por ele faria todo toque parecer lento. A mudança escrita no
cache é `planReducer(p, { type: "done", id })`, o reducer da aula 9, então o plano otimista é calculado pela
mesma regra que o servidor aplica. Interromper as queries antes importa: uma busca que já estava a caminho
poderia chegar depois da escrita otimista e sobrescrevê-la com o plano antigo.

**Quando o servidor recusa, a tela precisa dizer isso, não só desfazer.** O `usePlan` do planner devolve o
`error` da mutation para isso; a aula 11 o mostra ao lado do formulário que acrescenta sessões.

## Três testes

Salve isto como `__tests__/done.test.tsx`. Cada teste marca como feita a sessão de violão do dia 21 pela aba
*This week* e lê o total em *Courses*:

```tsx
// __tests__/done.test.tsx: marking done shows at once, reaches the server, and is undone if the server refuses.
import { NavigationContainer } from "@react-navigation/native";
import { onlineManager } from "@tanstack/react-query";
import { fireEvent, render, screen, waitFor } from "@testing-library/react-native";
import data from "../src/courses.json";
import { fetchPlan, sendDone } from "../src/api";
import { markDone } from "../src/planner";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

jest.mock("../src/api");
// What the server holds after the press: the same plan, with s3 done.
beforeEach(() => {
  jest.clearAllMocks();
  jest.mocked(fetchPlan).mockResolvedValue(markDone(structuredClone(data), "s3"));
});
const markGuitar = { name: "Mark 20 min on 2026-10-21 done" };

async function openWeekAndMark() {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(withPlan(<NavigationContainer><RootNavigator /></NavigationContainer>));
  await fireEvent.press(screen.getByText("This week"));
  await fireEvent.press(screen.getByRole("button", markGuitar));
  await fireEvent.press(screen.getByText("Courses"));
}

test("the total moves at once, and the server is told", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  await waitFor(() => expect(sendDone).toHaveBeenCalledWith("s3", expect.anything()));
});

test("a refusal puts the total back", async () => {
  jest.mocked(sendDone).mockRejectedValue(new Error("POST /sessions/s3/done answered 500"));
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data)); // the server did not change
  await openWeekAndMark();
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});

test("offline, the request waits; online again, it is sent", async () => {
  jest.mocked(sendDone).mockResolvedValue({ id: "s3", course: "guitar", date: "2026-10-21", minutes: 20, done: true });
  onlineManager.setOnline(false);
  await openWeekAndMark();
  expect(await screen.findByText("This week: 95 of 125 minutes done")).toBeOnTheScreen();
  expect(sendDone).not.toHaveBeenCalled();
  onlineManager.setOnline(true);
  await waitFor(() => expect(sendDone).toHaveBeenCalledTimes(1));
});
```

```
ana@dev:~/planner$ npx jest done
PASS __tests__/done.test.tsx
  ✓ the total moves at once, and the server is told (324 ms)
  ✓ a refusal puts the total back (75 ms)
  ✓ offline, the request waits; online again, it is sent (83 ms)

Test Suites: 1 passed, 1 total
Tests:       3 passed, 3 total
Snapshots:   0 total
Time:        1.448 s, estimated 2 s
Ran all test suites matching done.
```

O primeiro teste mostra a mudança na hora e a requisição feita. O segundo faz o servidor recusar, e o total volta
a 75: isso é o `onError`. O terceiro é da próxima seção.
