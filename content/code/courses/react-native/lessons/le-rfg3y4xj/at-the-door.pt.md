---
title: Corrigindo na porta
version: 1
---

**O `weekTotal` não estava errado; ele confiou num valor que ninguém tinha conferido.** O servidor é outro
programa, publicado no próprio calendário, e qualquer coisa que ele manda pode mudar de forma. O lugar de
conferir é onde a resposta dele entra, uma vez, para toda tela atrás poder confiar no plano que recebe. No
`src/api.ts`, o `fetchPlan` confere antes de devolver:

```ts
// src/api.ts: the requests the planner makes, and nothing about screens.
import type { Plan, Session } from "./planner";

const BASE = process.env.EXPO_PUBLIC_API_URL ?? "http://localhost:8008";

async function json<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(BASE + path, init);
  if (!res.ok) {
    const body = await res.json().catch(() => null); // a refusal may explain itself
    throw new Error(body?.error ?? `${init?.method ?? "GET"} ${path} answered ${res.status}`);
  }
  return (await res.json()) as T;
}

export type NewSession = { course: string; date: string; minutes: number };

// The server is another program, deployed on its own schedule: what it sends is checked, not trusted.
function isPlan(x: unknown): x is Plan {
  const p = x as Plan | null;
  return typeof p === "object" && p !== null && Array.isArray(p.courses) && Array.isArray(p.sessions);
}

export async function fetchPlan(): Promise<Plan> {
  const plan = await json<unknown>("/plan");
  if (!isPlan(plan)) throw new Error("the server sent a plan this version of the planner cannot read");
  return plan;
}

export const sendDone = (id: string) => json<Session>(`/sessions/${id}/done`, { method: "POST" });
export const createSession = (s: NewSession) =>
  json<Session>("/sessions", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(s) });
```

**O `isPlan` confere só aquilo de que o app depende**: dois arrays. Ele é um *type guard*: quando devolve
verdadeiro, o TypeScript trata o valor como um `Plan` dali em diante. Uma conferência minuciosa de cada
campo é o que bibliotecas como o Zod fazem, e para uma API maior vale a pena. Um plano que falha lança um
erro com uma frase, e o erro vai para onde vai toda requisição falha da aula 10: o TanStack Query tenta de
novo, depois mostra *The plan could not be loaded* com o motivo.

Dois testes, com o `fetch` trocado em cada um. Salve o `__tests__/api.test.ts`:

```ts
// __tests__/api.test.ts: a plan in a shape the app cannot read is refused at the door, with a sentence.
import { fetchPlan } from "../src/api";

const answer = (body: unknown) =>
  jest.spyOn(globalThis, "fetch").mockResolvedValue(new Response(JSON.stringify(body), { status: 200 }));

test("a plan with courses and sessions is accepted", async () => {
  answer({ courses: [], sessions: [] });
  await expect(fetchPlan()).resolves.toEqual({ courses: [], sessions: [] });
});

test("a plan whose sessions were renamed is refused", async () => {
  answer({ courses: [], items: [] });
  await expect(fetchPlan()).rejects.toThrow("cannot read");
});
```

Depois o mesmo servidor quebrado de novo, contra uma exportação nova:

```
ana@dev:~/planner$ npx jest api.test --verbose --forceExit 2>&1 | grep -E "✓|Tests:"
  ✓ a plan with courses and sessions is accepted (334 ms)
  ✓ a plan whose sessions were renamed is refused (2 ms)
Tests:       2 passed, 2 total
ana@dev:~/planner$ node crash.mjs 'http://localhost:8082/?today=2026-10-21'
screen: The plan could not be loaded: the server sent a plan this version of the planner cannot read
ana@dev:~/planner$ npx jest --forceExit 2>&1 | tail -5
Tests:       62 passed, 62 total
Snapshots:   0 total
Time:        9.362 s
Ran all test suites.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

**Uma falha virou uma frase.** A pessoa vê que o plano não pôde ser lido e pode tentar de novo mais tarde; o
time vê exatamente qual versão não conseguiu ler o quê. Essa mensagem levou alguns segundos para aparecer,
porque o TanStack Query tentou mais três vezes antes, o que é certo para uma rede e errado para um servidor
que vai responder igual toda vez. *Distinguir os dois, e não repetir uma recusa, é uma mudança pequena na
opção `retry` da consulta que este curso deixa para você.*
