---
title: A mudança que não é mudança
version: 1
---

**Um signal decide se mudou comparando o valor novo com o antigo usando `Object.is`, então um objeto
ou um array alterado no lugar, para o signal, não mudou nada.** Esse é o bug que todo time encontra no
primeiro mês com signals, e ele não produz erro nenhum: a página simplesmente fica como estava. Um
programa mostra isso em seis linhas de saída:

```typescript
// try/equality.mts
import { computed, signal } from '@angular/core';

interface Session {
  minutes: number;
}

const sessions = signal<Session[]>([{ minutes: 30 }, { minutes: 60 }]);
const total = computed(() => sessions().reduce((sum, s) => sum + s.minutes, 0));
console.log('total:', total());

sessions().push({ minutes: 25 });
console.log('after push:', total(), 'with', sessions().length, 'sessions');

sessions.set(sessions());
console.log('after set to the same array:', total());

sessions.update((list) => [...list]);
console.log('after a new array:', total());

sessions.update((list) => [...list, { minutes: 50 }]);
console.log('after adding the right way:', total());
```

```
ana@dev:~/planner$ node try/equality.mts
total: 90
after push: 90 with 3 sessions
after set to the same array: 90
after a new array: 115
after adding the right way: 165
```

Leia as linhas do meio devagar. O `push` pôs uma terceira sessão no array, e o `total` continuou
dizendo 90: o signal guardava o mesmo objeto array, ninguém chamou `set` nem `update`, então nada
avisou o `total` de que ele estava velho. O `set` com esse mesmo array também não ajudou, porque o
`Object.is` achou o valor antigo e o novo o mesmo objeto. Só um **array novo** contou como mudança, e o
primeiro, feito por cópia, trouxe enfim o 25 para o total.

**A regra: nunca mude o que um signal guarda; dê a ele um valor novo.** Para um array,
`[...lista, item]` para acrescentar, `lista.filter(…)` para tirar, `lista.map(…)` para alterar um item,
cada um devolvendo um array novo. Para um objeto, `{ ...session, done: true }`. A mesma disciplina é a
que o OnPush da aula 7 e os stores da aula 22 pedem, então ela se paga três vezes.

## Quando igual deveria querer dizer outra coisa

A comparação pode ser trocada. Um signal criado com uma função `equal` usa essa função no lugar do
`Object.is`:

```typescript
const week = signal({ start: '2026-10-19', end: '2026-10-25' }, {
  equal: (a, b) => a.start === b.start && a.end === b.end,
});
```

Definir `week` com um objeto novo com as mesmas duas datas não é mudança, e nada que o lê é
incomodado. Raramente é necessário; use quando um valor é reconstruído com frequência e em geral fica
igual.
