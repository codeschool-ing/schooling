---
title: Um teste que falha
version: 1
---

**Um teste se paga no dia em que falha.** A checagem por que toda sessão passa, vinda de formulários e
da API, é a próxima coisa a fixar. Salve isto como `src/lib/server/check.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/server/check.test.ts", "parts": [
 {"code": "// check.test.ts: what problemWith accepts and refuses.\nimport { expect, test } from 'vitest';\nimport { problemWith } from '#lib/server/check.js';\n\ntest('a session with a date and a sensible length has no problem', () => {\n\texpect(problemWith({ date: '2026-10-21', minutes: 30 })).toBeUndefined();\n});\n"},
 {"code": "test.each([\n\t[{ date: '', minutes: 30 }, 'The session needs a date.'],\n\t[{ date: '2026-02-31', minutes: 30 }, 'The session needs a date.'],\n\t[{ date: '2026-10-21', minutes: 4 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: 601 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: 22.5 }, 'Minutes must be a whole number from 5 to 600.'],\n\t[{ date: '2026-10-21', minutes: '30' }, 'Minutes must be a whole number from 5 to 600.']\n])('%j is refused', (session, problem) => {\n\texpect(problemWith(session)).toBe(problem);\n});", "note": "Cada recusa que a checagem faz é uma linha, e a última é aquela de que a aula 18 tratou: minutos que chegam como texto."}
]}
```

```
ana@dev:~/planner$ npm run test:unit

> planner@0.0.1 test:unit
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/lib/server/check.test.ts (7 tests) 5ms
 ✓ src/lib/week.test.ts (11 tests) 21ms

 Test Files  2 passed (2)
      Tests  18 passed (18)
   Start at  22:34:17
   Duration  193ms (transform 45%, import 23%, tests 22%, worker 10%)
```

Agora quebre alguma coisa, do jeito que acontece: uma edição pequena, por um bom motivo, com uma
consequência em que ninguém pensou. Suponha que alguém decida que a semana deve incluir a segunda-feira
seguinte, e troque `<` por `<=` em `inWeek`:

```
ana@dev:~/planner$ sed -i 's/date < addDays(monday, 7)/date <= addDays(monday, 7)/' src/lib/week.ts
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | grep -B2 -A12 FAIL
⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/lib/week.test.ts > inWeek includes the Sunday and not the next Monday
AssertionError: expected true to be false // Object.is equality

- Expected
+ Received

- false
+ true

 ❯ src/lib/week.test.ts:25:45
     23| test('inWeek includes the Sunday and not the next Monday', () => {
     24|  expect(inWeek('2026-10-25', '2026-10-19')).toBe(true);
     25|  expect(inWeek('2026-10-26', '2026-10-19')).toBe(false);
```

**Um teste falha, e o nome dele diz o que quebrou**: a segunda-feira depois da semana agora conta nela.
A saída mostra a linha que falhou, o que ela esperava e o que recebeu. No próprio planner, as sessões de
toda segunda-feira teriam sido contadas em duas semanas, e o total da semana teria saído errado de um
jeito que parece plausível. Ponha a linha de volta:

```
ana@dev:~/planner$ sed -i 's/date <= addDays(monday, 7)/date < addDays(monday, 7)/' src/lib/week.ts
```

O teste não sabia para que servia a mudança. Ele sabia o que era verdade antes, e disse que não era
mais, que é tudo o que um teste consegue fazer e quase sempre basta.
