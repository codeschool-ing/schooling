---
title: Testando uma classe com runes
version: 1
---

**Um arquivo que usa runes precisa passar pelo compilador do Svelte, e um teste não é exceção.** A
classe do planner está em `planner.svelte.ts` por esse motivo, e um teste que queira um `$state` próprio
tem o nome no mesmo formato, `.svelte.test.ts`. Salve isto como `src/lib/planner.svelte.test.ts`:

```schooling-example
{"language": "typescript", "file": "src/lib/planner.svelte.test.ts", "parts": [
 {"code": "// planner.svelte.test.ts: the planner's totals, worked out from data the test controls.\nimport { expect, test } from 'vitest';\nimport { Planner, type PlannerSource } from '#lib/planner.svelte.js';\n"},
 {"code": "function source(): PlannerSource {\n\treturn {\n\t\tcourses: [\n\t\t\t{ id: 'algebra', name: 'Linear algebra' },\n\t\t\t{ id: 'guitar', name: 'Guitar' }\n\t\t],\n\t\tsessions: [\n\t\t\t{ id: 1, course: 'algebra', date: '2026-10-13', minutes: 60, done: true },\n\t\t\t{ id: 2, course: 'algebra', date: '2026-10-19', minutes: 90, done: true },\n\t\t\t{ id: 3, course: 'guitar', date: '2026-10-20', minutes: 45, done: false }\n\t\t],\n\t\tweek: '2026-10-19'\n\t};\n}\n", "note": "Uma cópia nova dos dados para cada teste, para que nenhum teste possa mudar o que outro vê."},
 {"code": "test('the totals count only the sessions in the week', () => {\n\tconst planner = new Planner(() => source());\n\texpect(planner.total).toBe(135);\n\texpect(planner.doneMinutes).toBe(90);\n\texpect(planner.byCourse).toEqual({ algebra: 90, guitar: 45 });\n});\n", "note": "O planner recebe uma função que devolve dados comuns, exatamente como o `PlannerProvider` lhe dá uma. Os deriveds calculam quando são lidos, como fariam numa página."},
 {"code": "test('the totals follow the data when it changes', () => {\n\tlet data = $state(source());\n\tconst planner = new Planner(() => data);\n\texpect(planner.total).toBe(135);\n\n\tdata.week = '2026-10-12';\n\texpect(planner.total).toBe(60);\n});", "note": "O `$state` no teste torna os dados reativos, como o `data` é num componente. Mudar a semana, do jeito que um endereço novo muda, muda o total, sem componente nenhum."}
]}
```

```
ana@dev:~/planner$ npm run test:unit 2>&1 | tail -6

 Test Files  3 passed (3)
      Tests  20 passed (20)
   Start at  22:34:20
   Duration  837ms (transform 82%, import 12%, tests 4%, worker 2%)
```

O segundo teste é a propriedade para a qual a aula 14 reconstruiu o planner: ele lê os dados em vez de
copiá-los, então quando os dados mudam, os totais acompanham. A aula 14 conferiu isso clicando num
navegador, uma vez. Este teste confere toda vez que os testes rodam, em milissegundos, sem navegador.
