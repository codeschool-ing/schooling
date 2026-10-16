---
title: O que quebra quando os testes rodam juntos
version: 1
---

**Um teste que passa sozinho e falha ao lado de outros está lendo algo que outro teste está
escrevendo.** Neste projeto, esse algo é a loja: uma cesta, uma oferta e uma lista de clientes,
guardadas na memória do servidor e compartilhadas por todo navegador que a abre. Cada worker tem o
próprio navegador, e a aula 10 mostrou que dois contextos de navegador não dividem cookies nem
armazenamento. Eles ainda dividem o servidor, e todo worker fala com o mesmo.

A primeira leitura de costume de uma execução paralela vermelha é que os testes são instáveis, e
que uma nova tentativa resolve. A aula 14 trata de testes instáveis, e a diferença importa aqui: um
teste instável falha por causa de um tempo dentro dele mesmo. Estes falham pelo que os **outros**
testes fizeram, e quais testes falham muda de execução para execução enquanto a causa fica onde
está.

## Quais testes rodavam no mesmo momento

O reporter list imprime os resultados na ordem em que chegam, o que não diz nada sobre o que rodou
ao lado do quê. O reporter JSON do Playwright registra, para cada teste, o worker que o rodou,
quando começou e quanto durou. O programa abaixo lê esse relatório e, para cada teste que não
terminou do jeito esperado, imprime os testes que outros workers rodavam quando ele começou. Salve-o
como `overlap.mjs`:

```javascript
// Reads a JSON report from Playwright and, for every test that ended in a
// way it was not expected to, names the tests that other workers were
// running in that test's first two seconds.
import { readFileSync } from 'node:fs';

// A test here resets the shop as it starts and checks the result within two
// seconds (the /ssr page of lesson 6 takes one and a half to come alive), so
// what other workers did in those two seconds is the suspect.
const WINDOW = 2000;

const report = JSON.parse(readFileSync(process.argv[2], 'utf8'));
const runs = [];
const visit = (suite) => {
  for (const spec of suite.specs ?? []) {
    for (const test of spec.tests) {
      for (const result of test.results) {
        const start = Date.parse(result.startTime);
        runs.push({
          name: `${spec.file}:${spec.line} ${spec.title}`,
          worker: result.workerIndex,
          start,
          end: start + result.duration,
          status: result.status,
          expected: test.expectedStatus,
          error: result.error?.message ?? '',
        });
      }
    }
  }
  for (const child of suite.suites ?? []) visit(child);
};
report.suites.forEach(visit);

const zero = Math.min(...runs.map((run) => run.start));
const at = (ms) => `${((ms - zero) / 1000).toFixed(1)}s`;
const plain = (text) => text.replace(/\u001b\[[0-9;]*m/g, '');

for (const run of runs) {
  if (run.status === run.expected || run.status === 'skipped') continue;
  console.log(`${run.name}  worker ${run.worker}  ${at(run.start)} to ${at(run.end)}`);
  const lines = plain(run.error).split('\n');
  console.log(`  ${lines[0]}`);
  for (const line of lines) {
    if (/^(Expected|Received)/.test(line)) console.log(`  ${line}`);
  }
  for (const other of runs) {
    if (other.worker !== run.worker && other.worker >= 0
        && other.start < run.start + WINDOW && other.end > run.start) {
      console.log(`    beside it: ${other.name}  worker ${other.worker}  ${at(other.start)} to ${at(other.end)}`);
    }
  }
}
```

Um teste que o relatório considera certo tem o `status` igual ao `expectedStatus`: `passed` para a
maioria, `failed` para os que o `test.fail()` marca. Um teste `skipped` não rodou, então não colidiu
com nada. Todo o resto é impresso com a primeira linha do erro, as linhas `Expected` e `Received`, e
os testes de outros workers cuja execução se sobrepôs aos dois primeiros segundos dele. Essa janela
é um julgamento escrito no programa: todo teste aqui reinicia a loja e a confere dentro desse
tempo, então o que outro worker fez depois é um suspeito improvável.

Rode a suíte com quatro workers, gravando o relatório JSON num arquivo, e leia-o:

```
ana@laptop:~/quitanda$ PLAYWRIGHT_JSON_OUTPUT_FILE=run.json npx playwright test --workers 4 --reporter=list,json | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  2 failed
  59 passed (15.5s)
```

```
ana@laptop:~/quitanda$ node overlap.mjs run.json
cache.spec.js:7 a new offer reaches the page  worker 2  0.0s to 5.3s
  Error: expect(locator).toContainText(expected) failed
  Expected substring: "Banana"
  Received string:    "Mango for R$ 3,90"
    beside it: banana.spec.js:3 a banana goes into the basket  worker 0  0.0s to 0.4s
    beside it: basket-data.spec.js:14 a banana costs R$ 5,90  worker 1  0.0s to 0.4s
    beside it: basket-data.spec.js:21 two mangoes cost R$ 9,00  worker 1  0.7s to 1.0s
    beside it: conditions.spec.js:13 waitForFunction: filled, the search settles on papaya  worker 3  0.0s to 0.4s
    beside it: conditions.spec.js:20 waitForFunction: typed, the search settles on papaya  worker 3  0.6s to 1.6s
    beside it: conditions.spec.js:30 expect.poll: the server has the banana from /ssr  worker 3  1.6s to 3.4s
    beside it: contexts.spec.js:8 two contexts share nothing in the browser  worker 0  0.6s to 1.1s
    beside it: contexts.spec.js:31 two shoppers, one basket: the shop's flaw  worker 0  1.1s to 1.6s
    beside it: contexts.spec.js:57 the page fixture: storage written in one test  worker 0  1.6s to 1.7s
    beside it: contexts.spec.js:63 the next test in the same browser starts without it  worker 0  1.8s to 1.9s
    beside it: deals.spec.js:10 gets the page for a phone  worker 1  1.1s to 1.2s
    beside it: deals.spec.js:20 gets the page for a desktop  worker 1  1.2s to 1.3s
    beside it: headless.spec.js:3 every product is fully on the first screen  worker 1  1.3s to 1.5s
    beside it: headless.spec.js:9 the page is the size the test asked for  worker 1  1.5s to 1.7s
    beside it: headless.spec.js:15 a headless desktop browser gets the desktop deals page  worker 1  1.7s to 1.8s
    beside it: locators.spec.js:7 banana, by its test id  worker 1  1.9s to 2.1s
    beside it: names.spec.js:5 four ways to make a name  worker 0  2.0s to 2.0s
    beside it: no-script.spec.js:6 /ssr lists its eight products without a script  worker 0  2.0s to 2.1s
conditions.spec.js:40 toPass: the count and the total change together  worker 3  3.4s to 8.6s
  Error: expect(received).toBe(expected) // Object.is equality
  Expected: "1"
  Received: "2"
    beside it: cache.spec.js:7 a new offer reaches the page  worker 2  0.0s to 5.3s
    beside it: page-object.spec.js:15 the total follows the price  worker 0  3.2s to 3.5s
    beside it: responsive.spec.js:45 nothing scrolls sideways at 360 px  worker 1  3.8s to 4.0s
    beside it: responsive.spec.js:45 nothing scrolls sideways at 390 px  worker 1  4.0s to 4.1s
    beside it: responsive.spec.js:45 nothing scrolls sideways at 768 px  worker 1  4.1s to 4.3s
    beside it: responsive.spec.js:27 the links show and the Menu button does not  worker 1  3.3s to 3.6s
    beside it: responsive.spec.js:27 the links show and the Menu button does not  worker 1  3.6s to 3.8s
    beside it: search.spec.js:7 one request: filling the box finds papaya  worker 0  3.6s to 3.7s
    beside it: search.spec.js:13 typed key by key, the list settles on papaya  worker 0  3.7s to 9.8s
    beside it: setup-cost.spec.js:6 ten customers through the form  worker 1  4.3s to 6.0s
```

Duas falhas, e nenhuma é só sobre a cesta. O `cache.spec.js:7` publicou uma oferta nova e depois
leu a antiga, *Mango for R$ 3,90*. Nos dois primeiros segundos dele, `banana`, `basket-data`,
`conditions` e `contexts` estavam começando em outros workers, e todos começam com um reset, que
devolve a oferta para a manga. O `conditions.spec.js:40` pôs uma manga e contou dois itens: o
`page-object.spec.js:15` estava pondo um mamão no worker 0 no mesmo momento. O programa aponta
suspeitos, não culpados; o que transforma um suspeito em culpado é ler o que aquele teste faz, e os
que importam aqui são os testes que reiniciam a loja ou escrevem nela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 324\" role=\"img\" aria-label=\"As quatro faixas de uma execução com quatro workers, ao longo de 15 segundos. Cada barra é um teste; as barras vivas são testes que reiniciam a loja ou escrevem nela, as apagadas testes que a deixam em paz. 2 barras têm contorno de falha: cache.spec.js:7, conditions.spec.js:40. Todas são barras vivas, e todas correm enquanto barras vivas correm em outras faixas.\"><text x=\"70.0\" y=\"87.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">faixa 0</text><line x1=\"80\" y1=\"96\" x2=\"700\" y2=\"96\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></line><rect x=\"80.0\" y=\"76\" width=\"15.6\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"106.4\" y=\"76\" width=\"17.2\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"125.4\" y=\"76\" width=\"19.7\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"146.4\" y=\"76\" width=\"5.2\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"152.9\" y=\"76\" width=\"6.1\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"161.3\" y=\"76\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"162.4\" y=\"76\" width=\"5.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"168.5\" y=\"76\" width=\"4.8\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"174.9\" y=\"76\" width=\"9.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"185.4\" y=\"76\" width=\"5.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"192.6\" y=\"76\" width=\"8.1\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"201.9\" y=\"76\" width=\"11.1\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"214.3\" y=\"76\" width=\"9.9\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"227.0\" y=\"76\" width=\"6.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"234.6\" y=\"76\" width=\"249.8\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"486.4\" y=\"76\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"489.0\" y=\"76\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"490.6\" y=\"76\" width=\"13.2\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"505.1\" y=\"76\" width=\"125.8\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"70.0\" y=\"133.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">faixa 1</text><line x1=\"80\" y1=\"142\" x2=\"700\" y2=\"142\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></line><rect x=\"80.8\" y=\"122\" width=\"15.9\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"109.5\" y=\"122\" width=\"13.2\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"125.3\" y=\"122\" width=\"4.6\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"131.0\" y=\"122\" width=\"3.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"135.8\" y=\"122\" width=\"6.1\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"143.7\" y=\"122\" width=\"6.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"151.2\" y=\"122\" width=\"4.2\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"157.5\" y=\"122\" width=\"7.0\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"165.8\" y=\"122\" width=\"8.4\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"175.7\" y=\"122\" width=\"6.3\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"183.7\" y=\"122\" width=\"6.2\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"191.1\" y=\"122\" width=\"4.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"237.1\" y=\"122\" width=\"6.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"244.9\" y=\"122\" width=\"5.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"251.4\" y=\"122\" width=\"5.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"197.0\" y=\"122\" width=\"8.0\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"206.1\" y=\"122\" width=\"10.4\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"217.8\" y=\"122\" width=\"10.3\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"229.7\" y=\"122\" width=\"6.2\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"257.8\" y=\"122\" width=\"71.2\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"330.0\" y=\"122\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"332.5\" y=\"122\" width=\"10.7\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"344.3\" y=\"122\" width=\"11.6\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"357.3\" y=\"122\" width=\"7.2\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"365.7\" y=\"122\" width=\"7.0\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"373.9\" y=\"122\" width=\"86.9\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"462.0\" y=\"122\" width=\"5.4\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"468.8\" y=\"122\" width=\"8.9\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"478.9\" y=\"122\" width=\"45.6\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"526.0\" y=\"122\" width=\"4.1\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"531.8\" y=\"122\" width=\"129.6\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"70.0\" y=\"179.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">faixa 2</text><line x1=\"80\" y1=\"188\" x2=\"700\" y2=\"188\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></line><rect x=\"80.1\" y=\"168\" width=\"218.2\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"2\"></rect><rect x=\"340.4\" y=\"168\" width=\"216.7\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"562.5\" y=\"168\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"564.1\" y=\"168\" width=\"1.5\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"565.9\" y=\"168\" width=\"7.7\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"70.0\" y=\"225.0\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">faixa 3</text><line x1=\"80\" y1=\"234\" x2=\"700\" y2=\"234\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></line><rect x=\"81.4\" y=\"214\" width=\"13.8\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"103.3\" y=\"214\" width=\"40.9\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"148.0\" y=\"214\" width=\"72.6\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><rect x=\"222.4\" y=\"214\" width=\"211.9\" height=\"16\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"2\"></rect><rect x=\"470.2\" y=\"214\" width=\"9.7\" height=\"16\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><rect x=\"487.8\" y=\"214\" width=\"86.6\" height=\"16\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"80.1\" y=\"164.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">cache.spec.js:7</text><text x=\"222.4\" y=\"210.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">conditions.spec.js:40</text><text x=\"80.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"162.7\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><text x=\"245.3\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><text x=\"328.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"410.7\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">8</text><text x=\"493.3\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">10</text><text x=\"576.0\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><text x=\"658.7\" y=\"266.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">14</text><text x=\"390.0\" y=\"284.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">segundos desde o início da execução</text><rect x=\"80\" y=\"18\" width=\"14\" height=\"12\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"100.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">reinicia a loja ou escreve nela</text><rect x=\"306.20000000000005\" y=\"18\" width=\"14\" height=\"12\" rx=\"1\" fill=\"var(--phosphor-dim)\"></rect><text x=\"326.2\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">deixa a loja em paz</text><rect x=\"458.00000000000006\" y=\"18\" width=\"14\" height=\"12\" rx=\"1\" fill=\"var(--scan)\" stroke=\"var(--paper)\" stroke-width=\"2\"></rect><text x=\"478.0\" y=\"28.0\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">falhou, sem que se esperasse</text></svg>", "caption": "A primeira execução com quatro workers, desenhada a partir do relatório JSON. Todo teste que falhou mexe na loja, e correu enquanto outros testes que mexem nela corriam em outra faixa."}
```

O mesmo comando de novo, um minuto depois:

```
ana@laptop:~/quitanda$ PLAYWRIGHT_JSON_OUTPUT_FILE=run2.json npx playwright test --workers 4 --reporter=list,json | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  4 failed
  1 did not run
  56 passed (19.5s)
```

```
ana@laptop:~/quitanda$ node overlap.mjs run2.json
basket-data.spec.js:14 a banana costs R$ 5,90  worker 1  0.1s to 5.5s
  Error: expect(locator).toHaveText(expected) failed
  Expected: "1"
  Received: "2"
    beside it: banana.spec.js:3 a banana goes into the basket  worker 0  0.0s to 0.5s
    beside it: cache.spec.js:7 a new offer reaches the page  worker 2  0.1s to 0.5s
    beside it: cache.spec.js:13 a returning customer sees the new offer  worker 2  0.7s to 6.0s
    beside it: conditions.spec.js:13 waitForFunction: filled, the search settles on papaya  worker 3  0.0s to 0.4s
    beside it: conditions.spec.js:20 waitForFunction: typed, the search settles on papaya  worker 3  0.6s to 1.6s
    beside it: conditions.spec.js:30 expect.poll: the server has the banana from /ssr  worker 3  1.6s to 4.2s
    beside it: contexts.spec.js:8 two contexts share nothing in the browser  worker 0  0.7s to 1.1s
    beside it: contexts.spec.js:31 two shoppers, one basket: the shop's flaw  worker 0  1.1s to 1.6s
    beside it: contexts.spec.js:57 the page fixture: storage written in one test  worker 0  1.6s to 1.7s
    beside it: contexts.spec.js:63 the next test in the same browser starts without it  worker 0  1.8s to 1.9s
    beside it: deals.spec.js:10 gets the page for a phone  worker 0  1.9s to 2.0s
    beside it: deals.spec.js:20 gets the page for a desktop  worker 0  2.0s to 2.1s
conditions.spec.js:40 toPass: the count and the total change together  worker 3  4.2s to 9.3s
  Error: expect(received).toBe(expected) // Object.is equality
  Expected: "1"
  Received: "2"
    beside it: basket-data.spec.js:14 a banana costs R$ 5,90  worker 1  0.1s to 5.5s
    beside it: cache.spec.js:13 a returning customer sees the new offer  worker 2  0.7s to 6.0s
    beside it: cache.spec.js:22 the offer is checked with the server before it is reused  worker 2  6.0s to 6.0s
    beside it: cache.spec.js:28 a static file is reused only when the server agrees  worker 2  6.1s to 6.1s
    beside it: cache.spec.js:40 routing hides the flaw  worker 2  6.1s to 6.3s
    beside it: page-object.spec.js:8 two fruit make two items  worker 0  4.0s to 9.3s
page-object.spec.js:8 two fruit make two items  worker 0  4.0s to 9.3s
  Error: expect(locator).toHaveText(expected) failed
  Expected: "2"
  Received: "1"
    beside it: basket-data.spec.js:14 a banana costs R$ 5,90  worker 1  0.1s to 5.5s
    beside it: cache.spec.js:13 a returning customer sees the new offer  worker 2  0.7s to 6.0s
    beside it: conditions.spec.js:30 expect.poll: the server has the banana from /ssr  worker 3  1.6s to 4.2s
    beside it: conditions.spec.js:40 toPass: the count and the total change together  worker 3  4.2s to 9.3s
ssr.spec.js:8 a click on /ssr adds to the basket once the page is ready  worker 6  11.1s to 18.1s
  Error: expect(locator).toHaveText(expected) failed
  Expected: "1"
  Received: "3"
    beside it: search.spec.js:13 typed key by key, the list settles on papaya  worker 2  6.5s to 12.6s
    beside it: sleeps.spec.js:18 a click on /ssr adds to the basket  worker 4  10.1s to 12.2s
    beside it: sleeps.spec.js:25 searching for papaya finds one fruit  worker 4  12.3s to 12.4s
    beside it: spa.spec.js:3 Basket opens the basket without loading a page  worker 5  10.9s to 11.1s
    beside it: spa.spec.js:18 Basket opens the basket on a slow network  worker 5  11.1s to 12.2s
    beside it: spa.spec.js:30 the basket opens from its own address  worker 5  12.2s to 12.3s
    beside it: targets.spec.js:11 every target on a phone is 24 by 24, or was judged  worker 5  12.3s to 12.7s
    beside it: toast.spec.js:7 adding a banana says so, then stops saying it  worker 4  12.4s to 15.5s
    beside it: waiting.spec.js:7 a read is a snapshot, an assertion retries  worker 2  12.6s to 15.7s
```

Quatro falhas desta vez, e mais um teste que não rodou porque um teste antes dele, no mesmo
arquivo serial, tinha falhado. O `basket-data.spec.js:14` contou dois onde pôs um, ao lado do
`banana.spec.js` pondo a banana dele. O `conditions.spec.js:40` e o `page-object.spec.js:8` começaram a
um quinto de segundo um do outro e se quebraram: um viu 2 onde esperava 1, o outro 1 onde esperava
2. O `ssr.spec.js:8` contou três. E há um **worker 6** numa execução de quatro. Depois que um teste
falha, o Playwright joga aquele worker fora e abre um novo com o número seguinte, então o próximo
teste ganha um navegador novo, e não um que uma falha pode ter deixado no meio de alguma coisa. **A causa não se mexeu; as vítimas, sim.** Qual teste perde depende de quais testes
calham de dividir o mesmo segundo, e isso é decidido por quanto cada um levou naquela execução.

## Por que o reset no começo não os salva

Cada um desses arquivos começa com `request.post('/api/reset')` num `beforeEach`. A aula 15 mostrou
por que isso não basta: um reset deixa a loja vazia **num momento**, e o teste passa as centenas de
milissegundos seguintes supondo que ela continua assim. Com quatro workers, qualquer outro teste
pode pôr uma banana, ou reiniciar a cesta que o primeiro acabou de encher, dentro dessa janela. O
`app/store.js` deixa o segundo caso mais largo do que parece, porque o `reset()` restaura a cesta,
a oferta e os clientes juntos: um teste sobre a oferta esvazia a cesta de alguém, e um teste sobre
a cesta apaga o cliente novo de alguém.

Há três respostas, em ordem do quanto resolvem:

| | o que faz | quanto custa |
|---|---|---|
| `--workers 1` | nada roda ao lado de nada | a suíte inteira na velocidade mais lenta |
| os testes que mexem na loja esperam a vez | só eles perdem o paralelismo | uma lista para manter, e a próxima seção é essa lista |
| uma cesta por visitante | cada teste ganha os próprios dados | uma mudança na aplicação, o pedido da aula 15 aos desenvolvedores |

**A última é a correção de verdade.** A aula 15 deixou os clientes únicos e pediu uma cesta por
visitante; até a loja ter uma, os testes que usam a cesta não podem ser mantidos fora do caminho uns
dos outros pelo lado de fora. A resposta do meio é a que um testador pode aplicar hoje.
