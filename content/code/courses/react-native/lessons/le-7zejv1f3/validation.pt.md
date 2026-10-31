---
title: Validação, com uma frase para cada recusa
version: 1
---

**Validação é uma função de um rascunho para os erros dele**, e ela pertence a um arquivo próprio, onde pode ser
testada sem tela. A do planner diz o que está errado em cada campo com palavras com que uma pessoa consegue
agir. Salve isto como `src/validate.ts`:

```typescript
// src/validate.ts: what the form refuses, and the sentence it gives for each refusal.
export type Draft = { date: string; minutes: string };
export type Errors = Partial<Record<keyof Draft, string>>;

export function validate({ date, minutes }: Draft): Errors {
  const errors: Errors = {};
  const d = new Date(`${date}T12:00:00Z`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || Number.isNaN(d.getTime()) || d.toISOString().slice(0, 10) !== date) {
    errors.date = "Write the date as YYYY-MM-DD, for example 2026-10-23.";
  }
  const n = Number(minutes);
  if (minutes.trim() === "" || !Number.isInteger(n)) errors.minutes = "Write the minutes as a whole number.";
  else if (n < 5 || n > 240) errors.minutes = "A session is between 5 and 240 minutes.";
  return errors;
}
```

O `Errors` guarda no máximo uma frase por campo. Um objeto vazio quer dizer que o rascunho está bom.

**A data é conferida por ida e volta, não só por padrão.** `2026-02-30` casa com `\d{4}-\d{2}-\d{2}`, e o `Date`
do JavaScript a transforma em silêncio em 2 de março. Interpretar a data e escrevê-la de volta pega isso: o que
volta não é o que entrou.

**Os minutos têm duas frases**, porque "não é número inteiro" e "não está entre 5 e 240" são dois erros
diferentes com duas correções diferentes. Uma mensagem que dissesse só *inválido* deixaria a pessoa adivinhando
qual.

## Testada, cada recusa

O `test.each` roda um teste por linha de uma tabela, o que cai exatamente bem num validador. Salve isto como
`__tests__/validate.test.ts`:

```typescript
// __tests__/validate.test.ts: each refusal, and its sentence.
import { validate } from "../src/validate";

test("a good draft has no errors", () => {
  expect(validate({ date: "2026-10-23", minutes: "25" })).toEqual({});
});

test.each([
  ["23/10/2026", "25", "date"],
  ["2026-02-30", "25", "date"],
  ["2026-10-23", "", "minutes"],
  ["2026-10-23", "2.5", "minutes"],
  ["2026-10-23", "300", "minutes"],
])("date %s and minutes %s are refused for %s", (date, minutes, field) => {
  expect(Object.keys(validate({ date, minutes }))).toEqual([field]);
});
```

```
ana@dev:~/planner$ npx jest validate --forceExit
PASS __tests__/validate.test.ts
  ✓ a good draft has no errors (5 ms)
  ✓ date 23/10/2026 and minutes 25 are refused for date (2 ms)
  ✓ date 2026-02-30 and minutes 25 are refused for date (8 ms)
  ✓ date 2026-10-23 and minutes  are refused for minutes (1 ms)
  ✓ date 2026-10-23 and minutes 2.5 are refused for minutes (1 ms)
  ✓ date 2026-10-23 and minutes 300 are refused for minutes (1 ms)

Test Suites: 1 passed, 1 total
Tests:       6 passed, 6 total
Snapshots:   0 total
Time:        0.547 s, estimated 1 s
Ran all test suites matching validate.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

O `--forceExit` encerra o Jest quando os testes terminam, o que a última linha informa; a partir desta aula os
testes do planner rodam com ele, porque os temporizadores do query client de outro jeito mantêm uma execução
aberta. Cada linha confere que um rascunho é recusado **pelo campo certo e só por ele**: uma data errada não
pode também acusar os minutos, ou a pessoa lê dois erros para um engano.

## Quando mostrar os erros

O planner valida quando a pessoa aperta *Save*, não a cada tecla. Gritar *Write the date as YYYY-MM-DD* depois
do primeiro dígito de uma data é hostil. Depois de um salvamento que falhou, os erros ficam até o próximo
salvamento, para que corrigir um campo não faça a mensagem dele sumir no meio do caminho. Validar quando a
pessoa sai de cada campo é um meio-termo razoável, e a função acima o serve sem mudança.
