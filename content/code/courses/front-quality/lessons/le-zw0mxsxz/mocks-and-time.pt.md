---
title: Substitutos para o que um teste não controla
version: 1
---

**Um teste controla as suas entradas, e duas das entradas do planner não são argumentos: o que a
página faz com um plano novo, e que horas são.** O Vitest troca as duas por substitutos que pertencem
ao teste, e é só isso que um mock é.

## Uma função que registra suas chamadas

O `render` não guarda um plano novo; ele o entrega ao `update` e deixa quem chamou decidir. No segundo
teste de componente, o `update` era `vi.fn()`, uma função que não faz nada além de lembrar como foi
chamada. O `update.mock.calls[0][0]` é o primeiro argumento da primeira chamada: o plano que o
`render` entregou quando o Done foi clicado.

Repare no que esse teste conferiu. Não que o `markDone` foi chamado, que é como o `view.ts` faz isso
hoje, mas **o que saiu**: um plano em que a sessão 4 está feita. O mock é um jeito de ler a saída de
uma função cuja saída é uma chamada, e o conselho da aula 1 continua valendo através dele.

## Um relógio que o teste acerta

O `today()` lê o relógio do computador, então um teste dele teria uma resposta diferente a cada dia. O
Vitest consegue parar o relógio e acertá-lo. Salve isto como `src/today.test.ts`:

```typescript
// src/today.test.ts
import { afterEach, expect, test, vi } from "vitest";
import { today } from "./planner";

afterEach(() => {
  vi.useRealTimers();
});

test("today is the date on the student's own calendar", () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-22T22:30:00-03:00"));
  expect(today()).toBe("2026-10-22");
});

test("late in the evening it is still today, though UTC is already tomorrow", () => {
  vi.useFakeTimers();
  vi.setSystemTime(new Date("2026-10-22T23:59:00-03:00"));
  expect(new Date().toISOString().slice(0, 10)).toBe("2026-10-23");
  expect(today()).toBe("2026-10-22");
});
```

O `vi.useFakeTimers()` troca o `Date` e os temporizadores por versões que o Vitest controla, e o
`setSystemTime` diz o que o `new Date()` devolve dali em diante. O `afterEach` devolve o relógio real,
então nenhum outro teste herda um relógio parado. O segundo teste fixa o motivo de o `today()` existir:
o atalho óbvio, `toISOString().slice(0, 10)`, dá a data do UTC, que em São Paulo vira amanhã às nove
de toda noite.

```
ana@dev:~/planner$ npx vitest run src/today.test.ts

 RUN  v5.0.5 /home/ana/planner


 Test Files  1 passed (1)
      Tests  2 passed (2)
   Start at  19:52:55
   Duration  186ms (transform 69%, import 17%, tests 8%, worker 6%)
```

Este arquivo depende do fuso de propósito, como o código que testa: o `today()` deve seguir o
calendário da própria máquina. Ele foi gravado com `TZ=America/Sao_Paulo`, que as datas dentro dele
dizem em voz alta com o `-03:00`. **Um teste que é sobre um fuso deve dizer qual**, nos dados, para
que alguém lendo a falha em outra máquina saiba por quê.

## Quando não usar um substituto

Cada substituto é um lugar onde o teste deixa de ser sobre a coisa real. Trocar o `weekTotal` dentro
de um teste do `view.ts` deixaria o teste mais rápido em nada e cego para o defeito que o primeiro
teste achou. Troque o que o teste não consegue controlar, o relógio, a rede, um número aleatório, e
deixe o resto real.
