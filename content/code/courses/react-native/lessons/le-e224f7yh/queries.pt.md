---
title: O plano como uma query
version: 1
---

**Uma query é uma leitura com uma chave.** `useQuery({ queryKey: ["plan"], queryFn: fetchPlan })` pede o plano; o
primeiro componente a pedir faz a requisição, todo outro que pede `["plan"]` compartilha a resposta, e o
resultado fica num cache que dura mais que as telas. Instale a biblioteca, e o NetInfo, que diz a ela quando o
celular está online:

```
ana@dev:~/planner$ npm install -E @tanstack/react-query@5.105.0 @react-native-community/netinfo@12.0.1

added 3 packages, and audited 1094 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## O planState, por trás do mesmo hook

O `src/planState.tsx` mantém o tipo `Action` e o reducer, e põe uma query e uma mutation por trás do
`usePlan()`. Troque-o por:

```tsx
// src/planState.tsx: the plan comes from the server through TanStack Query; every change is an action.
import { onlineManager, useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import NetInfo from "@react-native-community/netinfo";
import { fetchPlan, sendDone } from "./api";
import { addSession, markDone, type Plan } from "./planner";

export type Action =
  | { type: "done"; id: string }
  | { type: "add"; course: string; date: string; minutes: number };

export function planReducer(plan: Plan, action: Action): Plan {
  switch (action.type) {
    case "done":
      return markDone(plan, action.id);
    case "add":
      return addSession(plan, action.course, action.date, action.minutes);
  }
}

// TanStack Query pauses requests while offline; on a phone, NetInfo is what knows.
onlineManager.setEventListener((setOnline) => NetInfo.addEventListener((s) => setOnline(!!s.isConnected)));

export function usePlanQuery() {
  return useQuery({ queryKey: ["plan"], queryFn: fetchPlan, staleTime: 30_000 });
}

function useMarkDone() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: sendDone,
    onMutate: async (id: string) => {
      await client.cancelQueries({ queryKey: ["plan"] });
      const before = client.getQueryData<Plan>(["plan"]);
      client.setQueryData<Plan>(["plan"], (p) => p && planReducer(p, { type: "done", id }));
      return { before };
    },
    onError: (_error, _id, context) => client.setQueryData(["plan"], context?.before),
    onSettled: () => client.invalidateQueries({ queryKey: ["plan"] }),
  });
}

// The screens' view of all this is the same as in lesson 9.
export function usePlan() {
  const { data } = usePlanQuery();
  const markDone = useMarkDone();
  if (!data) throw new Error("usePlan must be used once the plan has loaded");
  const dispatch = (action: Action) => {
    if (action.type === "done") markDone.mutate(action.id);
  };
  return { plan: data, dispatch, error: markDone.error };
}
```

Esta seção é a metade da query. O `usePlanQuery` lê `["plan"]` com um `staleTime` de 30 segundos: por esse tempo
depois de uma resposta, uma tela que monta pega o plano em cache sem perguntar de novo. Depois dele, o plano está
**velho**, o que não quer dizer jogado fora; quer dizer que a próxima tela que o quiser recebe a cópia em cache
na hora **e** uma requisição em segundo plano, cuja resposta a substitui.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l10-stale\" aria-label=\"Uma linha do tempo da consulta do plano. Em 0 segundos o plano é buscado e está fresco. Até 30 segundos, o staleTime, uma tela que pede recebe o plano em cache sem requisição. Depois de 30 segundos o plano está velho: uma tela que pede recebe o plano em cache na hora e uma requisição em segundo plano, cuja resposta o substitui. Uma mutação invalida a consulta, deixando-a velha na hora.\"><defs><marker id=\"l10-stale-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l10-stale-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M30 132 L700 132\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><rect x=\"40\" y=\"80\" width=\"260\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">fresco: sem requisição</text><rect x=\"300\" y=\"80\" width=\"380\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"490\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">velho: cache na hora, busca por trás</text><text x=\"40\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0 s</text><text x=\"300\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">30 s</text><text x=\"60\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">buscado</text><path d=\"M60 66 L60 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"170\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">uma tela pede</text><path d=\"M170 46 L170 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"430\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper)\">uma tela pede</text><path d=\"M430 46 L430 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-stale-ah-paper-dim)\"></path><text x=\"220\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">uma mutação invalida: velho já</text><path d=\"M220 164 L220 120\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l10-stale-ah-amber)\"></path></svg>", "caption": "Velho não é vazio: um plano velho aparece na hora, e é trocado quando a requisição em segundo plano responde."}
```

O `usePlan` lança um erro se o plano não chegou. É uma promessa que a raiz cumpre: nenhuma tela é desenhada
antes de ele chegar.

## A raiz espera, e diz isso

O `App.tsx` ganha um `QueryClientProvider`, que guarda o cache, e um componente que só desenha os navegadores
quando o plano está ali. Até lá ele diz o que está acontecendo, num `status` que um leitor de tela anuncia, e
quando o carregamento falhou ele diz por quê e oferece tentar de novo. Troque-o por:

```tsx
// App.tsx: the planner's root: safe areas, the query client, and the plan once it has arrived.
import { NavigationContainer } from "@react-navigation/native";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { StatusBar } from "expo-status-bar";
import { Pressable, Text, View } from "react-native";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";
import { usePlanQuery } from "./src/planState";

const client = new QueryClient();

function Loaded() {
  const { data, error, refetch, isFetching } = usePlanQuery();
  if (data) {
    return (
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
    );
  }
  return (
    <View style={{ flex: 1, justifyContent: "center", padding: 24, gap: 12 }}>
      <Text role="status">{error ? `The plan could not be loaded: ${error.message}` : "Loading the plan"}</Text>
      {error && !isFetching && (
        <Pressable role="button" onPress={() => refetch()}>
          <Text>Try again</Text>
        </Pressable>
      )}
    </View>
  );
}

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <QueryClientProvider client={client}>
        <Loaded />
      </QueryClientProvider>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

**Um carregamento que falhou é uma frase e um botão, nunca uma tela em branco.** O TanStack Query tenta de novo
uma query que falhou três vezes por padrão, esperando mais a cada vez, antes de desistir; a mensagem aparece
depois dessas tentativas. O `isFetching` esconde o botão enquanto uma nova tentativa está em curso, para ele não
ser apertado duas vezes.

## Testes, sem servidor

Um teste não pode contar com um servidor rodando. **O `jest.mock("../src/api")` troca cada export daquele
arquivo por um mock** que não faz nada até um teste dizer o que ele devolve, o que transforma *o que o servidor
responde* numa linha por teste.

O NetInfo tem um lado nativo, então precisa do substituto dele no `jest.setup.ts`, ao lado do da aula 6. Troque-o:

```typescript
// jest.setup.ts: runs before every test file.
// The libraries' own stand-ins: there is no native side in Jest to measure or to ask.
jest.mock("react-native-safe-area-context", () => require("react-native-safe-area-context/jest/mock").default);
jest.mock("@react-native-community/netinfo", () => require("@react-native-community/netinfo/jest/netinfo-mock.js"));
```

As telas abaixo da raiz precisam do plano já carregado. Um helper faz isso para todo teste, pondo o plano direto
num cache novo. Salve-o como `test-utils.tsx`, fora de `__tests__/` para o Jest não tomá-lo por um teste:

```tsx
// test-utils.tsx: what a screen test puts around a screen: a query client whose plan has already loaded.
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import type { ReactElement } from "react";
import data from "./src/courses.json";
import type { Plan } from "./src/planner";

export function withPlan(ui: ReactElement, plan: Plan = data) {
  const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
  client.setQueryData(["plan"], plan);
  return <QueryClientProvider client={client}>{ui}</QueryClientProvider>;
}
```

O teste do próprio app agora confere o estado de carregamento e depois o plano. Troque o
`__tests__/App.test.tsx`:

```tsx
// __tests__/App.test.tsx: the app waits for the plan, and says so when it cannot have it.
import { render, screen } from "@testing-library/react-native";
import data from "../src/courses.json";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api"); // no server in a test: each test says what the server answers

beforeEach(() => jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") }));

test("loading, then the plan", async () => {
  jest.mocked(fetchPlan).mockResolvedValue(structuredClone(data));
  await render(<App />);
  expect(screen.getByRole("status")).toHaveTextContent("Loading the plan");
  expect(await screen.findByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
});
```

E um novo confere a falha. Salve-o como `__tests__/failure.test.tsx`:

```tsx
// __tests__/failure.test.tsx: a server that is down is a sentence and a button, not a blank screen.
import { render, screen } from "@testing-library/react-native";
import App from "../App";
import { fetchPlan } from "../src/api";

jest.mock("../src/api");

test("the plan cannot be loaded", async () => {
  jest.mocked(fetchPlan).mockRejectedValue(new Error("GET /plan answered 503"));
  await render(<App />);
  expect(await screen.findByText("The plan could not be loaded: GET /plan answered 503", {}, { timeout: 10_000 })).toBeOnTheScreen();
  expect(screen.getByRole("button", { name: "Try again" })).toBeOnTheScreen();
}, 15_000);
```

Ele dá dez segundos, porque as três novas tentativas levam vários segundos de tempo real. Os dois testes de
navegação embrulham os navegadores em `withPlan(…)` em vez do provider da aula 9. Troque os dois:

```tsx
// __tests__/navigation.test.tsx: pressing a course opens its screen, and an address opens it too.
import { getStateFromPath, NavigationContainer } from "@react-navigation/native";
import { fireEvent, render, screen } from "@testing-library/react-native";
import { linking, RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

test("pressing a course pushes its screen", async () => {
  await render(
    withPlan(
      <NavigationContainer>
        <RootNavigator />
      </NavigationContainer>,
    ),
  );
  await fireEvent.press(screen.getByRole("button", { name: /^Guitar/ }));
  expect(screen.getAllByRole("heading").map((h) => h.props.children)).toEqual(["2026-10-21", "2026-10-28"]);
  expect(screen.getAllByText("20 min")).toHaveLength(2);
});

test("the address course/statistics reaches the Course screen with its id", () => {
  const state = getStateFromPath("course/statistics", linking.config);
  expect(state?.routes.at(-1)).toMatchObject({ name: "Course", params: { id: "statistics" } });
});
```

```tsx
// __tests__/PlanScreen.test.tsx: the Courses tab, read the way a screen reader reads it,
// inside a safe-area provider that pretends to be a phone with a notch.
import { NavigationContainer } from "@react-navigation/native";
import { render, screen } from "@testing-library/react-native";
import { SafeAreaProvider } from "react-native-safe-area-context";
import { RootNavigator } from "../src/navigation";
import { withPlan } from "../test-utils";

const phone = { frame: { x: 0, y: 0, width: 390, height: 844 }, insets: { top: 47, left: 0, right: 0, bottom: 34 } };

test("every course is a button named for what it holds, beside the two tabs", async () => {
  jest.useFakeTimers({ now: new Date("2026-10-21T12:00:00Z") });
  await render(
    <SafeAreaProvider initialMetrics={phone}>
      {withPlan(
        <NavigationContainer>
          <RootNavigator />
        </NavigationContainer>,
      )}
    </SafeAreaProvider>,
  );
  expect(screen.getByRole("button", { name: "Spanish A2 2 sessions planned" })).toBeOnTheScreen();
  expect(screen.getByText("This week: 75 of 125 minutes done")).toBeOnTheScreen();
  expect(screen.getByText("This week")).toBeOnTheScreen(); // the second tab's label
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest App failure navigation PlanScreen
PASS __tests__/navigation.test.tsx
PASS __tests__/App.test.tsx
PASS __tests__/PlanScreen.test.tsx
PASS __tests__/failure.test.tsx (8.185 s)
A worker process has failed to exit gracefully and has been force exited. This is likely caused by tests leaking due to improper teardown. Try running with --detectOpenHandles to find leaks. Active timers can also cause this, ensure that .unref() was called on them.

Test Suites: 4 passed, 4 total
Tests:       5 passed, 5 total
Snapshots:   0 total
Time:        9.006 s
Ran all test suites matching App|failure|navigation|PlanScreen.
```

*The plan could not be loaded: GET /plan answered 503* é o que uma pessoa leria, palavra por palavra, no dia em
que o servidor estiver fora do ar. O aviso do Jest sobre um worker que *failed to exit gracefully* também vem
desse teste: o query client do app vive tanto quanto o módulo, e os temporizadores dele duram mais que o teste.
Isso não muda nenhum resultado; uma suíte que cresce daria a cada teste o próprio client, como o `withPlan` faz.
