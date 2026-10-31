---
title: O plano como estado, mudado por ações
version: 1
---

**Até esta aula, cada tela importava o arquivo de dados sozinha.** Marcar uma sessão como feita numa tela
não conseguia mudar o total em outra, porque cada uma guardava a própria cópia. A correção é manter **um**
plano, como estado, no topo do app, e deixar toda tela lê-lo.

Quando o estado muda de mais de um jeito, o `useReducer` é mais claro que o `useState`. Você descreve cada
mudança como uma **ação**, um pequeno objeto dizendo o que aconteceu, e escreve uma função, o **reducer**,
que recebe o plano atual e uma ação e devolve o próximo plano. As regras do planner da aula 3 já são funções
assim, então o reducer só encaminha cada ação para uma delas. Salve isto como `src/planState.tsx`:

```schooling-example
{"language": "tsx", "file": "src/planState.tsx", "parts": [{"code": "// src/planState.tsx: the plan as state, changed only by actions, shared by every screen.\nimport { createContext, useContext, useReducer, type Dispatch, type ReactNode } from \"react\";\nimport { addSession, markDone, type Plan } from \"./planner\";\n", "note": "O estado do plano precisa dos hooks de contexto e de reducer do React, e das regras da aula 3."}, {"code": "export type Action =\n  | { type: \"done\"; id: string }\n  | { type: \"add\"; course: string; date: string; minutes: number };\n", "note": "**Toda mudança por que o plano pode passar, como um tipo.** Uma união: uma ação tem uma forma ou a outra, e o TypeScript sabe que campos cada uma traz."}, {"code": "export function planReducer(plan: Plan, action: Action): Plan {\n  switch (action.type) {\n    case \"done\":\n      return markDone(plan, action.id);\n    case \"add\":\n      return addSession(plan, action.course, action.date, action.minutes);\n  }\n}\n", "note": "O reducer: o plano e uma ação entram, o próximo plano sai. Cada caso entrega o trabalho a uma regra que já existe, então nada aqui pode discordar do `src/planner.ts`."}, {"code": "const PlanContext = createContext<{ plan: Plan; dispatch: Dispatch<Action> } | null>(null);\n", "note": "O contexto, guardando o plano e a função que envia ações. `null` até um provider lhe dar um valor."}, {"code": "export function PlanProvider({ initial, children }: { initial: Plan; children: ReactNode }) {\n  const [plan, dispatch] = useReducer(planReducer, initial);\n  return <PlanContext.Provider value={{ plan, dispatch }}>{children}</PlanContext.Provider>;\n}\n", "note": "O provider: o `useReducer` guarda o plano, a partir do `initial`, e todo componente abaixo pode lê-lo."}, {"code": "export function usePlan() {\n  const value = useContext(PlanContext);\n  if (!value) throw new Error(\"usePlan must be used inside a PlanProvider\");\n  return value;\n}", "note": "O hook que as telas chamam. Ele falha com uma frase, e não com uma falha mais adiante, quando ninguém forneceu um plano."}]}
```

O arquivo tem duas metades. Esta seção é a primeira: o tipo `Action` e o `planReducer`. **Um reducer nunca muda
o plano que recebe**, ele devolve um novo, que é o que `markDone` e `addSession` já fazem. É assim que o React
sabe que algo mudou: o plano novo é um objeto diferente do antigo.

A segunda metade, o contexto, é da próxima seção.

## Testado sem tela

Como o reducer é uma função comum, o teste dele não precisa de nada renderizado. Salve isto como
`__tests__/reducer.test.ts`:

```typescript
// __tests__/reducer.test.ts: every change to the plan is an action, checked with no screen.
import data from "../src/courses.json";
import { planReducer } from "../src/planState";
import { weekTotal, type Plan } from "../src/planner";

const plan: Plan = data;

test("marking a session done returns a new plan and leaves the old one alone", () => {
  const next = planReducer(plan, { type: "done", id: "s3" });
  expect(weekTotal(next, "2026-10-19").done).toBe(95);
  expect(weekTotal(plan, "2026-10-19").done).toBe(75);
  expect(next).not.toBe(plan);
});

test("adding a session goes through the same rules as before", () => {
  const next = planReducer(plan, { type: "add", course: "guitar", date: "2026-10-23", minutes: 25 });
  expect(next.sessions.at(-1)).toEqual({ id: "s7", course: "guitar", date: "2026-10-23", minutes: 25, done: false });
  expect(() => planReducer(plan, { type: "add", course: "chemistry", date: "2026-10-23", minutes: 25 })).toThrow("no course chemistry");
});
```

```
ana@dev:~/planner$ npx jest reducer
PASS __tests__/reducer.test.ts
  ✓ marking a session done returns a new plan and leaves the old one alone (4 ms)
  ✓ adding a session goes through the same rules as before (10 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.417 s, estimated 1 s
Ran all test suites matching reducer.
```

O primeiro teste também confere que o plano antigo continua intocado, `75` minutos feitos antes e `95`
depois, que é a propriedade de que o resto desta aula depende. O segundo confere que as regras da aula 3
continuam valendo quando uma mudança chega como ação: `chemistry` continua recusado.
