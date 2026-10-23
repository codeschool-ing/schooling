---
title: O primeiro teste, e ele está vermelho
version: 1
---

**Um teste unitário chama uma função com valores que escolheu e compara o que voltou com o que
esperava.** O `planner.ts` é feito exatamente desse tipo de função, então os primeiros testes dele
não precisam de nada além dos dados. Salve isto como `src/planner.test.ts`:

```typescript
// src/planner.test.ts
import { describe, expect, test } from "vitest";
import { addSession, markDone, weekOf, weekTotal, type Plan } from "./planner";
import data from "../public/courses.json";

const plan: Plan = data;

describe("weekOf", () => {
  test("a Wednesday's week runs from the Monday before to the Sunday after", () => {
    expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
  });
});

describe("weekTotal", () => {
  test("adds every session of the week, done or not", () => {
    expect(weekTotal(plan, "2026-10-21")).toBe(160);
  });

  test("can be limited to one course", () => {
    expect(weekTotal(plan, "2026-10-21", "javascript")).toBe(90);
  });
});
```

O `describe` agrupa testes sob um nome, o `test` é um teste, e o `expect(valor)` começa uma asserção.
O `toBe` compara com `===`, o que é certo para um número; o `toEqual` compara o conteúdo, que é o que
um array precisa, já que dois arrays com os mesmos itens ainda são dois arrays diferentes. Os dados
são o próprio arquivo do planner, importado direto, então o teste e o app leem as mesmas seis
sessões.

Os números foram calculados à mão, a partir do arquivo, antes de o teste rodar: de segunda 19 a
domingo 25 de outubro há 45, 60, 30 e 25 minutos, que dão 160, e as sessões de JavaScript nesse
intervalo são de 60 e 30. **Calcule o valor esperado você mesmo.** Um número copiado do que o código
mostrou é um teste de que o código concorda consigo mesmo.

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ src/planner.test.ts (3 tests | 2 failed) 14ms
   ❯ weekOf (1)
     × a Wednesday's week runs from the Monday before to the Sunday after 7ms
   ❯ weekTotal (2)
     × adds every session of the week, done or not 1ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 2 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekOf > a Wednesday's week runs from the Monday before to the Sunday after
AssertionError: expected [ '2026-10-20', '2026-10-26' ] to deeply equal [ '2026-10-19', '2026-10-25' ]

- Expected
+ Received

  [
-   "2026-10-19",
-   "2026-10-25",
+   "2026-10-20",
+   "2026-10-26",
  ]

 ❯ src/planner.test.ts:10:34
      8| describe("weekOf", () => {
      9|   test("a Wednesday's week runs from the Monday before to the Sunday a…
     10|     expect(weekOf("2026-10-21")).toEqual(["2026-10-19", "2026-10-25"]);
       |                                  ^
     11|   });
     12| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/2]⎯

 FAIL  src/planner.test.ts > weekTotal > adds every session of the week, done or not
AssertionError: expected 155 to be 160 // Object.is equality

- Expected
+ Received

- 160
+ 155

 ❯ src/planner.test.ts:16:43
     14| describe("weekTotal", () => {
     15|   test("adds every session of the week, done or not", () => {
     16|     expect(weekTotal(plan, "2026-10-21")).toBe(160);
       |                                           ^
     17|   });
     18|

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[2/2]⎯


 Test Files  1 failed (1)
      Tests  2 failed | 1 passed (3)
   Start at  19:52:47
   Duration  239ms (transform 68%, tests 14%, import 13%, worker 4%)
```

**Dois de três falham**, e o relatório diz como. O `weekOf` deu de terça 20 a segunda 26 em vez de
segunda 19 a domingo 25: a semana inteira está um dia atrasada. O total é 155 em vez de 160, que é o
mesmo erro visto de fora, já que uma semana atrasada em um dia perde os 45 minutos da segunda e ganha
os 40 da segunda seguinte. Só o total de JavaScript passa, e por sorte: as sessões dele caem numa
terça e numa quinta, bem dentro de qualquer uma das duas semanas.

É um defeito que estava no planner desde a aula 1, e todo total que a página mostrou estava errado.
Nada na tela dizia isso. A próxima seção descobre por quê.
