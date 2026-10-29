---
title: A aritmética, testada sozinha
version: 1
---

**O `planner.ts` guarda funções simples, e uma função simples se testa chamando.** O `weekOf` decide
quais dias são "esta semana", o `totals` soma os minutos, e o `parsePlanner` decide o que conta como
resposta do servidor. Toda tela do planner se apoia nessas três, e nenhuma delas sabe que o Angular
existe, então o teste delas também não:

```typescript
// src/app/planner.spec.ts
import { Session, parsePlanner, totals, weekOf } from './planner';

const session = (id: number, date: string, minutes: number, done: boolean): Session => ({
  id,
  courseId: 'git',
  date,
  minutes,
  done,
});

describe('weekOf', () => {
  it('starts on the Monday and ends on the Sunday', () => {
    expect(weekOf('2026-10-23')).toEqual({ start: '2026-10-19', end: '2026-10-25' });
  });

  it('puts a Sunday in the week that ends on it', () => {
    expect(weekOf('2026-10-25')).toEqual({ start: '2026-10-19', end: '2026-10-25' });
  });

  it('crosses the end of a month', () => {
    expect(weekOf('2026-10-28')).toEqual({ start: '2026-10-26', end: '2026-11-01' });
  });
});

describe('totals', () => {
  const week = { start: '2026-10-19', end: '2026-10-25' };

  it('counts what is planned and what is done, in the week only', () => {
    const sessions = [
      session(1, '2026-10-18', 45, true),
      session(2, '2026-10-19', 30, true),
      session(3, '2026-10-25', 50, false),
      session(4, '2026-10-26', 40, false),
    ];
    expect(totals(sessions, week)).toEqual({ planned: 80, done: 30 });
  });

  it('is zero for no sessions', () => {
    expect(totals([], week)).toEqual({ planned: 0, done: 0 });
  });
});

describe('parsePlanner', () => {
  it('accepts a planner', () => {
    const data = { courses: [], sessions: [session(1, '2026-10-19', 30, true)] };
    expect(parsePlanner(data)).toBe(data);
  });

  it('refuses minutes that are not a number', () => {
    const data = { courses: [], sessions: [{ ...session(5, '2026-10-24', 50, false), minutes: '50' }] };
    expect(() => parsePlanner(data)).toThrow('session 5: minutes is "50"');
  });

  it('refuses an answer with no sessions', () => {
    expect(() => parsePlanner({ courses: [] })).toThrow('no courses or no sessions');
  });
});
```

Cada teste é escolhido por um jeito de a função estar errada, não para passar por cada linha:

- **as bordas da semana.** Uma sexta no meio é o caso fácil. O domingo é o que um erro de um dia põe
  na semana errada, porque o `getDay()` do JavaScript chama o domingo de 0, o começo, e a semana do
  planner termina nele. Uma semana atravessando o fim de outubro confere que o `setDate` vira o mês.
- **as bordas dos totais.** Sessões no primeiro e no último dia da semana contam, os dias logo fora
  não, e uma sessão é planejada esteja concluída ou não.
- **as recusas, com as palavras delas.** O `toThrow` com um pedaço da mensagem confere que o erro diz
  qual sessão e qual campo, que é o que a aula 12 o fez dizer para uma pessoa poder agir.

O `session(...)` no topo é um helper que monta uma sessão a partir dos quatro valores que importam a
um teste. Testes são código, e a mesma regra de não se repetir vale; o que um leitor deve ver em cada
teste é só o que o faz diferente.

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓|Tests '
 ✓ |planner| src/app/planner.spec.ts (8 tests) 8ms
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 51ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 12ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 99ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 8ms
 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 2ms
 ✓ |planner| src/app/week/week.spec.ts (1 test) 95ms
      Tests  18 passed (18)
```

## Um teste que nunca falhou não foi testado

Oito testes passando dizem que o código concorda com eles hoje. Para saber que eles notariam um erro,
cometa um. Semanas que começam no domingo são uma convenção real, e um deslize plausível:

```
ana@dev:~/planner$ sed -i 's/(date.getDay() + 6) % 7/date.getDay()/' src/app/planner.ts
```

```
ana@dev:~/planner$ npx ng test --watch=false 2>&1 | grep -E '✓|❯|×|Tests '
❯ Building...
 ✓ |planner| src/app/week-summary/week-summary.spec.ts (1 test) 64ms
 ✓ |planner| src/app/autofocus.spec.ts (1 test) 18ms
 ❯ |planner| src/app/planner.spec.ts (8 tests | 3 failed) 20ms
     × starts on the Monday and ends on the Sunday 10ms
     × puts a Sunday in the week that ends on it 2ms
     × crosses the end of a month 2ms
     ✓ counts what is planned and what is done, in the week only 1ms
     ✓ is zero for no sessions 1ms
     ✓ accepts a planner 1ms
     ✓ refuses minutes that are not a number 2ms
     ✓ refuses an answer with no sessions 1ms
 ✓ |planner| src/app/app.spec.ts (2 tests) 100ms
 ✓ |planner| src/app/minutes-pipe.spec.ts (4 tests) 3ms
 ✓ |planner| src/app/planner-store.spec.ts (1 test) 14ms
 ❯ |planner| src/app/week/week.spec.ts (1 test | 1 failed) 130ms
     × counts the week that holds today 128ms
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 4 ⎯⎯⎯⎯⎯⎯⎯
 ❯ src/app/planner.spec.ts:14:34
 ❯ src/app/planner.spec.ts:18:34
 ❯ src/app/planner.spec.ts:22:34
 ❯ src/app/week/week.spec.ts:16:18
      Tests  4 failed | 14 passed (18)
```

Quatro testes falharam: os três do `weekOf`, que juntos dão nome ao problema, toda semana começando
um dia antes; e o teste do próprio `Week`, da aula 10, que confere a mesma regra de muito mais longe,
por uma página renderizada, e só pode dizer que um intervalo de datas não é o que ele esperava. As
telas também mostrariam, mas só para quem soubesse que datas procurar. Ponha a linha de volta:

```
ana@dev:~/planner$ git checkout -- src/app/planner.ts
```
