---
title: Os primeiros testes do planner
version: 1
---

**Um pipeline vale o que valem as conferências dentro dele, e até aqui o planner tem uma: a de tipos.**
Tipos pegam os minutos de uma sessão virando string. Não pegam uma semana que conta oito dias, que é o
tipo de erro que um planner de fato publica. Para isso é preciso um teste: código que chama `weekTotal`
com sessões cuja resposta você calculou à mão, e falha se a resposta for outra.

Testes são o assunto de front-quality, aulas 1 a 4. Esta seção acrescenta o menor conjunto útil, porque um
pipeline sem testes ensinaria a lição errada sobre para que serve o CI.

## Vitest

O **Vitest** é um executor de testes construído sobre o Vite, então lê o TypeScript do projeto sem
configuração própria. Instale-o fixado, como todo o resto, e dê ao projeto um script `test` com o
`npm pkg`, que edita o `package.json` sem abri-lo:

```
ana@dev:~/planner$ npm install --save-dev --save-exact vitest@5.0.5

added 20 packages, and audited 39 packages in 3s

13 packages are looking for funding
  run `npm fund` for details

found 0 vulnerabilities
ana@dev:~/planner$ npm pkg set scripts.test="vitest run"
ana@dev:~/planner$ grep -A1 "\"vitest\"\|\"test\"" package.json
    "test": "vitest run"
  },
--
    "vitest": "5.0.5"
  }
```

O **Vitest 5.0.5** está agora no `package.json`, e `npm test` o roda uma vez e sai, que é o que um
pipeline precisa; o `vitest` puro ficaria esperando mudanças.

## Os testes

O `planner.ts` não tem DOM, e foi por isso que a aula 1 o manteve assim: toda função pode ser chamada e
conferida sem navegador. Um arquivo ao lado dele guarda os testes:

```schooling-example
{"language": "typescript", "file": "src/planner.test.ts", "parts": [
 {"code": "// src/planner.test.ts\nimport { describe, expect, test } from \"vitest\";\nimport { addSession, markDone, mondayOf, weekTotal, type Session } from \"./planner\";", "note": "O Vitest acha qualquer arquivo terminado em `.test.ts`. `test` dá nome a um caso, `expect` afirma o que precisa ser verdade, e `describe` agrupa os casos sob a função de que tratam."},
 {"code": "\nconst sessions: Session[] = [\n  { id: 1, course: \"git\", date: \"2026-10-11\", minutes: 30, done: true },\n  { id: 2, course: \"git\", date: \"2026-10-12\", minutes: 60, done: true },\n  { id: 3, course: \"git\", date: \"2026-10-18\", minutes: 25, done: false },\n  { id: 4, course: \"git\", date: \"2026-10-19\", minutes: 45, done: false },\n];", "note": "Quatro sessões escolhidas pelas bordas: um domingo antes da semana, a segunda dela, o domingo dela, e a segunda seguinte. Uma semana está certa quando as duas do meio contam e as duas de fora não."},
 {"code": "\ndescribe(\"mondayOf\", () => {\n  test(\"a Monday is its own week's start\", () => {\n    expect(mondayOf(\"2026-10-12\")).toBe(\"2026-10-12\");\n  });\n  test(\"a Sunday belongs to the week before\", () => {\n    expect(mondayOf(\"2026-10-18\")).toBe(\"2026-10-12\");\n  });\n});", "note": "Domingo é o caso que quebra uma semana que começa na segunda, porque `getUTCDay()` o chama de dia 0."},
 {"code": "\ndescribe(\"weekTotal\", () => {\n  test(\"counts Monday to Sunday, and nothing either side\", () => {\n    expect(weekTotal(sessions, \"2026-10-12\")).toEqual({ planned: 85, done: 60 });\n  });\n});", "note": "Calculado à mão: 60 + 25 planejados, dos quais 60 feitos. `toEqual` compara o conteúdo do objeto, não a identidade dele."},
 {"code": "\ndescribe(\"addSession and markDone\", () => {\n  test(\"a new session takes the next id and starts not done\", () => {\n    const after = addSession(sessions, \"html-css\", \"2026-10-20\", 40);\n    expect(after.at(-1)).toEqual({ id: 5, course: \"html-css\", date: \"2026-10-20\", minutes: 40, done: false });\n    expect(sessions).toHaveLength(4);\n  });\n  test(\"marking one done leaves the others alone\", () => {\n    const after = markDone(sessions, 3);\n    expect(after.filter((s) => s.done).map((s) => s.id)).toEqual([1, 2, 3]);\n  });\n});", "note": "A última linha do primeiro caso confere que a lista original não mudou: as funções devolvem listas novas, e um teste é como essa promessa continua cumprida."}
]}
```

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ✓ src/planner.test.ts (5 tests) 9ms

 Test Files  1 passed (1)
      Tests  5 passed (5)
   Start at  19:52:08
   Duration  289ms (transform 69%, import 17%, tests 9%, worker 6%)
```

Cinco testes passam, em bem menos de um segundo. **Agora quebre a semana de propósito**: um caractere,
`<` para `<=`, deixa o fim da semana inclusivo, então a segunda seguinte também conta:

```
ana@dev:~/planner$ sed -i 's/s.date < end/s.date <= end/' src/planner.ts
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner

 ❯ src/planner.test.ts (5 tests | 1 failed) 19ms
   ✓ mondayOf (2)
     ✓ a Monday is its own week's start 3ms
     ✓ a Sunday belongs to the week before 0ms
   ❯ weekTotal (1)
     × counts Monday to Sunday, and nothing either side 11ms
   ✓ addSession and markDone (2)
     ✓ a new session takes the next id and starts not done 1ms
     ✓ marking one done leaves the others alone 1ms

⎯⎯⎯⎯⎯⎯⎯ Failed Tests 1 ⎯⎯⎯⎯⎯⎯⎯

 FAIL  src/planner.test.ts > weekTotal > counts Monday to Sunday, and nothing either side
AssertionError: expected { planned: 130, done: 60 } to deeply equal { planned: 85, done: 60 }

- Expected
+ Received

  {
    "done": 60,
-   "planned": 85,
+   "planned": 130,
  }

 ❯ src/planner.test.ts:23:47
     21| describe("weekTotal", () => {
     22|   test("counts Monday to Sunday, and nothing either side", () => {
     23|     expect(weekTotal(sessions, "2026-10-12")).toEqual({ planned: 85, d…
       |                                               ^
     24|   });
     25| });

⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯[1/1]⎯


 Test Files  1 failed (1)
      Tests  1 failed | 4 passed (5)
   Start at  19:52:09
   Duration  283ms (transform 55%, tests 20%, import 18%, worker 6%)
```

O teste que calculou a resposta à mão pegou, e disse o que esperava e o que recebeu: 130 minutos
planejados, porque a segunda seguinte agora conta. Nada mais teria pegado: os tipos estão certos, o build
está certo, e a página mostraria um número um pouco errado toda semana. Ponha a linha de volta e faça o
commit dos testes:

```
ana@dev:~/planner$ git checkout src/planner.ts
Updated 1 path from the index
ana@dev:~/planner$ git add package.json package-lock.json src/planner.test.ts
ana@dev:~/planner$ git commit -qm "Test the planner with Vitest"
```
