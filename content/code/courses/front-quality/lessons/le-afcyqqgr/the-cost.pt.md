---
title: Quanto custa um teste de navegador, medido
version: 1
---

**A aula 1 argumentou que o topo da pirâmide é lento e a base rápida; eis os números do próprio
planner.** As duas suítes, como estão no fim desta aula:

```
ana@dev:~/planner$ npm test

> planner@0.0.0 test
> vitest run


 RUN  v5.0.5 /home/ana/planner


 Test Files  4 passed (4)
      Tests  27 passed (27)
   Start at  19:54:00
   Duration  1.12s (environment 64%, tests 21%, import 11%, transform 2%, worker 1%)

ana@dev:~/planner$ npx playwright test

Running 5 tests using 2 workers

  ✓  2 [chromium] › e2e/empty.spec.ts:4:1 › a course with nothing planned says 0 for its week (444ms)
  ✓  1 [chromium] › e2e/planner.spec.ts:8:1 › the home page shows the week (450ms)
  ✓  3 [chromium] › e2e/planner.spec.ts:14:1 › a session added to a course counts in its week (416ms)
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (235ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (159ms)

  5 passed (3.1s)
```

**Vinte e sete testes no Vitest, pouco mais de um segundo, a maior parte subindo o jsdom. Cinco num
navegador de verdade, alguns segundos.** Um teste de navegador custa centenas de vezes mais que um teste
unitário, e o custo de partida é pago uma vez por execução, então a diferença é menor por teste do que
por suíte. As duas ainda são rápidas o bastante para rodar antes de cada push, e é esse o ponto a
defender: quando a suíte de navegador leva minutos, as pessoas param de rodá-la na própria máquina, e o
primeiro a ver uma falha é o servidor de CI.

## Onde cada suíte roda

- **Enquanto você escreve código**, o `npx vitest` no modo de observação: os testes unitários e de
  componente rodam de novo a cada salvamento, bem abaixo de um segundo cada.
- **Antes de um commit**, o `npm test` e o `npx playwright test`, os dois. Acrescente um script para ser
  um comando só:

```
ana@dev:~/planner$ npm pkg set scripts.check="npm test && npx playwright test"
ana@dev:~/planner$ npm run check 2>&1 | tail -n 4
  ✓  4 [chromium] › e2e/planner.spec.ts:24:1 › Done marks a session and takes its button away (234ms)
  ✓  5 [chromium] › e2e/planner.spec.ts:30:1 › a failed load says so (167ms)

  5 passed (2.4s)
```

- **Em todo pull request**, o mesmo `npm run check`, num servidor de CI, onde um resultado vermelho
  bloqueia o merge. Configurar isso é a aula 3 de `front-delivery`, sobre integração contínua.

## O que esta suíte ainda não confere

Todo teste até aqui pergunta se o planner **funciona**. Nenhum pergunta se ele é **confiável** com as
sessões de alguém, e nenhum pergunta se uma pessoa que não consegue usar um mouse, ou ver a tela,
consegue usá-lo. As aulas 5 a 9 são a primeira pergunta, e as aulas 10 a 13 a segunda, e as duas vão
acrescentar testes a estas duas suítes em vez de começar suítes novas.

```
ana@dev:~/planner$ git add -A
ana@dev:~/planner$ git commit -q -m "An empty course, and one command for both suites"
ana@dev:~/planner$ git log --oneline | head -n 3
abef326 An empty course, and one command for both suites
86a656b End-to-end tests with Playwright
aae0330 Start the app from a function a test can call
```
