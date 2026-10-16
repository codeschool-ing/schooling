---
title: Um worker para os testes que dividem a loja
version: 1
---

A aula 15 deu ao `tests/basket-data.spec.js` a linha `test.describe.configure({ mode: 'serial' })`
e disse o que ela não faz: mantém os testes de um arquivo em ordem, e os outros arquivos continuam
rodando ao lado. **O que a loja precisa é de uma regra sobre um grupo de arquivos**: estes nunca
rodam ao mesmo tempo uns que os outros, e todo o resto pode rodar em paralelo. No Playwright, essa
regra mora num **projeto**.

Um projeto é uma fatia da configuração com nome. A aula 10 usou três deles para rodar a suíte em
três navegadores. Um projeto também pode dizer quais arquivos contém, com `testMatch` e
`testIgnore`, e quantos workers pode usar ao mesmo tempo, com `workers`. O `workers` da execução
continua sendo o total; o número de um projeto deveria ser um teto dentro dele.

## Qual lista escrever

A lista óbvia é a dos arquivos que mexem na loja. É também a lista errada para manter. **Uma lista
de arquivos perigosos falha aberta**: um arquivo novo que reinicia a cesta, escrito no mês que vem
por alguém que nunca viu a lista, roda em paralelo por padrão e deixa a suíte vermelha em algumas
execuções e não em outras. A lista dos arquivos que sabidamente deixam a loja em paz falha do outro
jeito. Um arquivo novo que ninguém classificou cai junto dos testes que esperam a vez, onde fica
mais lento e nunca errado, e quem o quiser mais rápido precisa olhar para ele primeiro.

Treze dos vinte e cinco arquivos, trinta dos sessenta e um testes, não reiniciam a loja nem
escrevem nela: leem a página, o HTML, o layout ou a busca, ou criam clientes com nomes que ninguém
mais usa, como faz o `tests/setup-cost.spec.js` da aula 15. A configuração importa a do próprio projeto e acrescenta dois projetos. Salve-a
como `turns.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The shop keeps one basket, one offer and one list of customers for
// everybody, and a reset empties all three. Only the files listed here are
// known to leave them alone, so only they run in parallel. Every other file,
// including any file added after this list was written, runs in a project
// with one worker: one test at a time.
const leavesTheShopAlone = [
  'deals.spec.js',
  'headless.spec.js',
  'names.spec.js',
  'no-script.spec.js',
  'offline.spec.js',
  'page-object-card.spec.js',
  'responsive.spec.js',
  'search.spec.js',
  'setup-cost.spec.js',
  'smoke.spec.js',
  'spa.spec.js',
  'ssr-html.spec.js',
  'targets.spec.js',
];

export default defineConfig(base, {
  projects: [
    { name: 'parallel', testMatch: leavesTheShopAlone },
    { name: 'one-at-a-time', testIgnore: leavesTheShopAlone, workers: 1 },
  ],
});
```

Um nome de arquivo simples no `testMatch` casa em qualquer lugar abaixo do `testDir`, como
`**/deals.spec.js` casaria. O `playwright.config.js` não foi tocado, então um `npx playwright test`
simples continua rodando como a primeira seção mostrou; este arquivo é usado quando é nomeado.

## Conferir o teto, não a cor

Uma execução verde não prova que a regra valeu. Dois arquivos da loja podem se sobrepor e ainda
assim não colidir, porque uma colisão precisa que um escreva na janela do outro, então o resumo é a
prova errada. O relatório JSON tem o que é preciso: para cada teste, o projeto, quando começou e
quanto durou. O programa abaixo conta o máximo de testes de um projeto rodando no mesmo momento, e
imprime quantos testes da execução falharam. Salve-o como `at-once.mjs`:

```javascript
// Reads a JSON report from Playwright and prints the most tests of one
// project that were running at the same moment, and how many tests of the
// whole run ended in a way they were not expected to.
import { readFileSync } from 'node:fs';

const [file, project] = process.argv.slice(2);
const report = JSON.parse(readFileSync(file, 'utf8'));
const moments = [];
const visit = (suite) => {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      if (test.projectName !== project) continue;
      for (const result of test.results) {
        if (result.status === 'skipped') continue;
        const start = Date.parse(result.startTime);
        moments.push([start, +1], [start + result.duration, -1]);
      }
    }
  }
  for (const child of suite.suites ?? []) visit(child);
};
report.suites.forEach(visit);

// At the same instant, a test that ends is counted before one that starts.
moments.sort((a, b) => a[0] - b[0] || a[1] - b[1]);
let running = 0;
let most = 0;
for (const [, change] of moments) {
  running += change;
  most = Math.max(most, running);
}
console.log(`${project}: at most ${most} at once; ${report.stats.unexpected} failed`);
```

Cada início soma um e cada fim tira um; o ponto mais alto que a contagem alcança é a resposta, e com
`workers: 1` ela deveria ser 1. Cinco execuções com quatro workers e cinco com oito, cada uma
gravando o relatório JSON e conferindo-o:

```
ana@laptop:~/quitanda$ for w in 4 4 4 4 4 8 8 8 8 8; do PLAYWRIGHT_JSON_OUTPUT_FILE=turns.json npx playwright test --config turns.config.js --workers $w --reporter=json > /dev/null; printf "workers %s  " $w; node at-once.mjs turns.json one-at-a-time; done
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 2 at once; 1 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 2 at once; 1 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 3 at once; 2 failed
workers 8  one-at-a-time: at most 3 at once; 1 failed
workers 8  one-at-a-time: at most 3 at once; 2 failed
```

**O teto não se sustentou.** Em duas das cinco execuções com quatro workers, o projeto
um-de-cada-vez teve dois testes rodando ao mesmo tempo, e em três das cinco com oito teve três; toda
execução dessas fez um teste falhar, e toda execução em que a contagem ficou em 1 não fez nenhum. Um
resumo teria mostrado cinco execuções verdes e cinco vermelhas, sem motivo. A contagem diz que a
regra foi quebrada antes de qualquer coisa colidir.

## Por quê, e o arranjo que se sustenta

O motivo está em `node_modules/playwright/lib/runner/dispatcher.js`, na função
`_findFirstJobToRun`. Antes de entregar um arquivo de um projeto limitado, o dispatcher conta os
workers ocupados **cujo processo já pertence àquele projeto**. Um worker que rodou um arquivo do
`parallel` precisa ser fechado e trocado antes de rodar um do `one-at-a-time`, e enquanto isso
acontece ele está ocupado mas ainda conta como `parallel`. Quando vários workers ficam sem arquivos
do `parallel` ao mesmo tempo, cada um recebe um arquivo do `one-at-a-time`, e nenhum deles enxerga
os outros. Uma regra que se sustenta quando o tempo ajuda faz uma suíte que falha em algumas
execuções e não em outras, e a aula 14 trata dessas.

**O arranjo que se sustenta é impedir que os dois grupos se sobreponham no tempo.** Um projeto pode
nomear outro em `dependencies`, e o Playwright então os roda em **fases**: todos os testes da
dependência primeiro, depois o projeto que espera por ela. Cada fase ganha um dispatcher próprio,
começando sem workers, então a contagem de que o limite depende está certa desde o primeiro
arquivo. O mesmo arquivo, com `dependencies` acrescentado ao segundo projeto e os comentários
dizendo por quê. Salve-o como `turns.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The shop keeps one basket, one offer and one list of customers for
// everybody, and a reset empties all three. Only the files listed here are
// known to leave them alone, so only they run in parallel. Every other file,
// including any file added after this list was written, runs afterwards in a
// project with one worker: one test at a time.
const leavesTheShopAlone = [
  'deals.spec.js',
  'headless.spec.js',
  'names.spec.js',
  'no-script.spec.js',
  'offline.spec.js',
  'page-object-card.spec.js',
  'responsive.spec.js',
  'search.spec.js',
  'setup-cost.spec.js',
  'smoke.spec.js',
  'spa.spec.js',
  'ssr-html.spec.js',
  'targets.spec.js',
];

export default defineConfig(base, {
  projects: [
    { name: 'parallel', testMatch: leavesTheShopAlone },
    // A phase of its own: workers: 1 alone did not hold beside another
    // project in Playwright 1.56.
    {
      name: 'one-at-a-time',
      testIgnore: leavesTheShopAlone,
      workers: 1,
      dependencies: ['parallel'],
    },
  ],
});
```

As mesmas dez execuções:

```
ana@laptop:~/quitanda$ for w in 4 4 4 4 4 8 8 8 8 8; do PLAYWRIGHT_JSON_OUTPUT_FILE=turns.json npx playwright test --config turns.config.js --workers $w --reporter=json > /dev/null; printf "workers %s  " $w; node at-once.mjs turns.json one-at-a-time; done
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 4  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
workers 8  one-at-a-time: at most 1 at once; 0 failed
```

No máximo um de cada vez nas dez, e nada falhou.

## Quanto custa

| workers | `playwright.config.js` | `turns.config.js` |
|---|---|---|
| 1 | 37,0 s, todos os testes passaram | 37,9 s, todos os testes passaram |
| 2 | 28,1 s, 3 falharam | 33,0 s, todos os testes passaram |
| 4 | 16,7 s, 3 falharam | 33,1 s, todos os testes passaram |
| 8 | não rodado | 34,1 s, todos os testes passaram |

A coluna da esquerda são as execuções da primeira seção; a da direita é o mesmo comando com
`--config turns.config.js`, uma execução de cada:

```
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 1 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 1 worker
  61 passed (37.9s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 2 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 2 workers
  61 passed (33.0s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 4 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  61 passed (33.1s)
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --workers 8 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 8 workers
  61 passed (34.1s)
```

Verde custa tempo. Com quatro workers a execução leva 33,1 segundos em vez de 16,7, e quase não se
mexe entre dois workers e oito, porque trinta e um dos sessenta e um testes rodam um depois do outro
qualquer que seja a quantidade. **A fase um-de-cada-vez é um piso**: cada teste nela espera o anterior, nenhuma
quantidade de workers a encurta, e cada teste acrescentado a ela sobe o piso para todos.

As fases têm um segundo preço. Uma dependência que falha segura o projeto que espera por ela: o
próprio código do executor, em `lib/runner/tasks.js`, deixa de fora todo projeto cujas
dependências não passaram inteiras, então, se um teste do `parallel` falhar, o `one-at-a-time` não
roda. É o comportamento certo para os projetos de preparação para os quais as dependências foram
pensadas, e um incômodo aqui, onde os dois grupos não precisam um do outro: uma fase `parallel`
vermelha esconde se os testes da loja teriam passado.

Tudo isso é um custo pago em toda execução porque a loja guarda uma cesta só. O comentário no topo
do `turns.config.js` diz isso; no dia em que a loja ganhar uma cesta por visitante, o segundo
projeto é o que se apaga.
