---
title: Uma store, para quando o contexto não basta
version: 1
---

**Um contexto renderiza de novo todo leitor quando o valor dele muda.** Isso está bem para três telas e um
plano de seis sessões. Deixa de estar quando muitos componentes leem um valor grande e cada um usa uma parte
pequena dele: uma lista de mil linhas que leem cada uma um item, e um cabeçalho que lê o tema, todos
redesenhando porque uma linha foi marcada como feita.

Uma **store** guarda o estado fora do React e deixa cada componente assinar **a parte que usa**, por um
seletor. O Zustand é uma pequena e popular. Instale-o, na versão que este curso usou:

```
ana@dev:~/planner$ npm install -E zustand@5.0.16

added 1 package, and audited 1091 packages in 6s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

## Contando

Este teste monta os mesmos dois leitores duas vezes, um que mostra `done` e um que mostra o tema, uma vez por
um contexto e outra por uma store, depois muda `done` três vezes e conta as renderizações. Salve-o como
`__tests__/renders.test.tsx`:

```tsx
// __tests__/renders.test.tsx: who re-renders when one value changes, with a context and with a store.
import { act, render } from "@testing-library/react-native";
import { createContext, useContext, useState } from "react";
import { Text } from "react-native";
import { create } from "zustand";

type State = { done: number; theme: string };
const renders = { done: 0, theme: 0 };

// The same two readers, once through a context and once through a store.
const Ctx = createContext<State>({ done: 0, theme: "light" });
function DoneFromContext() {
  renders.done++;
  return <Text>{useContext(Ctx).done}</Text>;
}
function ThemeFromContext() {
  renders.theme++;
  return <Text>{useContext(Ctx).theme}</Text>;
}

const useStore = create<State>(() => ({ done: 0, theme: "light" }));
function DoneFromStore() {
  renders.done++;
  return <Text>{useStore((s) => s.done)}</Text>;
}
function ThemeFromStore() {
  renders.theme++;
  return <Text>{useStore((s) => s.theme)}</Text>;
}

test("a context re-renders every reader", async () => {
  let set: (s: State) => void = () => {};
  function Root() {
    const [state, setState] = useState<State>({ done: 0, theme: "light" });
    set = setState;
    return (
      <Ctx.Provider value={state}>
        <DoneFromContext />
        <ThemeFromContext />
      </Ctx.Provider>
    );
  }
  await render(<Root />);
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => set({ done, theme: "light" }));
  console.log("context: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});

test("a store re-renders only the readers whose slice changed", async () => {
  await render(
    <>
      <DoneFromStore />
      <ThemeFromStore />
    </>,
  );
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => useStore.setState({ done }));
  console.log("store: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});
```

```
ana@dev:~/planner$ npx jest renders
  console.log
    context: done rendered 3 times, theme rendered 3 times

      at Object.log (__tests__/renders.test.tsx:46:11)

  console.log
    store: done rendered 3 times, theme rendered 0 times

      at Object.log (__tests__/renders.test.tsx:58:11)

PASS __tests__/renders.test.tsx
  ✓ a context re-renders every reader (114 ms)
  ✓ a store re-renders only the readers whose slice changed (8 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.605 s, estimated 2 s
Ran all test suites matching renders.
```

**Pelo contexto, o leitor do tema renderizou três vezes por três mudanças que ele não mostra.** Pela store, não
renderizou nenhuma: o `useStore((s) => s.theme)` só renderiza o componente de novo quando o próprio tema muda. O
`act` embrulha cada mudança para o React terminar de renderizar antes de a contagem ser lida.

## O planner fica com o contexto

Três telas e um toque de vez em quando não precisam de uma store, e um contexto faz parte do React, sem
dependência e sem nada para aprender. **Recorra a uma store quando uma medição disser que as renderizações
custam algo**, que é o método da aula 19: uma lista de centenas de linhas que leem estado compartilhado é o
primeiro caso de costume. O teste acima é o tipo de medição que decide isso.

Existem outras stores, Redux Toolkit, Jotai, MobX, e elas diferem mais no estilo do que nesta propriedade. Toda
uma delas oferece um jeito de assinar parte do estado, que é o motivo de ter uma.
