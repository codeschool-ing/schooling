---
title: Mais casos, e os das bordas
version: 1
---

**Uma função com uma regra dentro merece um teste em cada borda da regra**, e um teste do meio diz
muito pouco. O `weekOf` tem sete dias para acertar, o `addSession` tem quatro motivos para recusar, e
os dois prometem deixar em paz o plano que receberam. Acrescente isto ao fim do
`src/planner.test.ts`:

```typescript
// src/planner.test.ts, below what is there
describe("weekOf, on every day of one week", () => {
  test.each(["2026-10-19", "2026-10-20", "2026-10-21", "2026-10-22", "2026-10-23", "2026-10-24", "2026-10-25"])(
    "%s is in the week of 19 October",
    (day) => {
      expect(weekOf(day)).toEqual(["2026-10-19", "2026-10-25"]);
    },
  );

  test("the week crosses into another month", () => {
    expect(weekOf("2026-11-01")).toEqual(["2026-10-26", "2026-11-01"]);
  });
});

describe("addSession", () => {
  test("gives the new session the next id, not done", () => {
    const next = addSession(plan, "git", "2026-10-23", 30);
    expect(next.sessions.at(-1)).toEqual({ id: 7, course: "git", date: "2026-10-23", minutes: 30, done: false });
  });

  test("leaves the plan it was given as it was", () => {
    const before = structuredClone(plan);
    addSession(plan, "git", "2026-10-23", 30);
    expect(plan).toEqual(before);
  });

  test.each([0, 601, 2.5, Number.NaN])("refuses %s minutes", (minutes) => {
    expect(() => addSession(plan, "git", "2026-10-23", minutes)).toThrow("minutes must be");
  });

  test("refuses a course that does not exist", () => {
    expect(() => addSession(plan, "rust", "2026-10-23", 30)).toThrow("no course rust");
  });

  test("refuses a date it cannot read", () => {
    expect(() => addSession(plan, "git", "23/10/2026", 30)).toThrow("not a date");
  });
});

describe("markDone", () => {
  test("marks that session and no other", () => {
    const next = markDone(plan, 4);
    expect(next.sessions.filter((s) => s.done).map((s) => s.id)).toEqual([1, 2, 3, 4]);
  });
});
```

O `test.each` roda o mesmo teste uma vez por valor, e o `%s` põe o valor no nome, então cada um dos
sete dias falha na própria linha se falhar. O `toThrow` recebe um pedaço da mensagem e passa se o erro
o contiver, o que basta para distinguir as quatro recusas. O `structuredClone` faz uma cópia
profunda, e o `.at(-1)` é a última sessão.

Os valores foram escolhidos, não sorteados. O `0` e o `601` ficam logo fora de 1 a 600, e o `0`
também é o que o `Number("")` dá, que é o que o formulário manda quando o campo fica vazio. O `2.5`
está dentro da faixa e não é inteiro, e o `NaN` é o que o `Number` faz de um texto que nem é número.
**Um valor logo fora de cada limite acha um erro de um; um valor no meio não acha nada.**

```
ana@dev:~/planner$ npx vitest run src/planner.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  20 passed (20)
   Start at  19:52:51
   Duration  179ms (transform 51%, import 25%, tests 17%, worker 7%)
```

Vinte testes, numa fração de segundo, e o nome de cada um diz o que o planner promete.
