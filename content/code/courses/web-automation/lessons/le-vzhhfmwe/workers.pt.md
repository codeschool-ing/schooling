---
title: Workers, e o que roda ao lado do quê
version: 1
---

**Um worker do Playwright é um processo Node separado, com o próprio navegador, e o executor
entrega a cada worker arquivos inteiros para rodar.** Vários workers rodam ao mesmo tempo, então
vários arquivos rodam ao mesmo tempo. Dentro de um arquivo, os testes continuam rodando um depois
do outro, na ordem em que foram escritos, no mesmo worker. A imagem comum é a contrária: que
"paralelo" quer dizer todos os testes começando juntos. Não quer, a menos que você peça.

O próprio executor é mais um processo. Ele lê a configuração, abre a loja pelo `webServer`, acha os
testes e mantém uma fila do que falta. Um worker que termina um arquivo recebe o próximo. Quando a
fila esvazia, o executor fecha os workers, fecha a loja e imprime o resumo.

## Quantos workers você ganha

Nada no `playwright.config.js` diz quantos, então o Playwright decide. A decisão está no pacote
instalado, numa linha de `node_modules/playwright/lib/common/config.js`:

```
ana@laptop:~/quitanda$ grep -n '"50%"' node_modules/playwright/lib/common/config.js
97:      workers: resolveWorkers(takeFirst(configCLIOverrides.debug ? 1 : void 0, configCLIOverrides.workers, userConfig.workers, "50%")),
```

O `--workers` da linha de comando vem primeiro, depois o `workers` da configuração, e, se nenhum
dos dois existir, `"50%"`. **Metade dos processadores lógicos da máquina, arredondada para baixo, e
nunca menos de um.** A função logo abaixo, `resolveWorkers`, transforma a porcentagem num número
com `os.cpus().length`. O notebook de onde vêm estas transcrições tem quatro:

```
ana@laptop:~/quitanda$ nproc
4
```

Então um `npx playwright test` simples roda dois workers aqui, e uma máquina com dezesseis threads
roda oito. A mesma suíte em duas máquinas é duas execuções diferentes, o que vale lembrar no dia em
que um teste falhar só numa delas.

## Arquivos em paralelo, testes de um arquivo em ordem

Três arquivos que deixam os dados da loja em paz, `responsive`, `headless` e `deals`, doze testes
ao todo, rodam com até quatro workers:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4

Running 12 tests using 3 workers

  ✓   1 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (234ms)
  ✓   2 tests/headless.spec.js:3:1 › every product is fully on the first screen (308ms)
  ✓   4 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (166ms)
  ✓   3 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (360ms)
  ✓   5 tests/headless.spec.js:9:1 › the page is the size the test asked for (180ms)
  ✓   7 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (133ms)
  ✓   6 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (265ms)
  ✓   8 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (167ms)
  ✓   9 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (117ms)
  ✘  10 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (153ms)
  ✘  11 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (136ms)
  ✓  12 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (119ms)

  12 passed (2.9s)
```

*Running 12 tests using 3 workers*: quatro eram permitidos e três foram abertos, porque só havia
três arquivos para entregar. Os números da segunda coluna são a ordem em que os testes começaram, e
a lista imprime cada linha quando um teste termina, então elas chegam fora de ordem assim que dois
workers se sobrepõem. Os dois testes do `responsive` que a aula 7 marcou com `test.fail()` mostram
o ✘ e ainda contam entre os que passaram: o teste falhou, que era o que ele esperava.

O `--fully-parallel` troca a unidade de trabalho do arquivo para o teste. Os mesmos três arquivos:

```
ana@laptop:~/quitanda$ npx playwright test tests/responsive.spec.js tests/headless.spec.js tests/deals.spec.js --workers 4 --fully-parallel

Running 12 tests using 4 workers

  ✓   3 tests/headless.spec.js:9:1 › the page is the size the test asked for (293ms)
  ✓   2 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (289ms)
  ✓   4 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (334ms)
  ✓   1 tests/headless.spec.js:3:1 › every product is fully on the first screen (386ms)
  ✓   5 tests/headless.spec.js:15:1 › a headless desktop browser gets the desktop deals page (156ms)
  ✓   8 tests/responsive.spec.js:27:5 › 601 px wide › the links show and the Menu button does not (264ms)
  ✓   6 tests/responsive.spec.js:10:5 › 360 px wide › the links hide behind the Menu button (356ms)
  ✓   9 tests/responsive.spec.js:27:5 › 1280 px wide › the links show and the Menu button does not (266ms)
  ✓   7 tests/responsive.spec.js:10:5 › 600 px wide › the links hide behind the Menu button (376ms)
  ✘  10 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 360 px (238ms)
  ✓  12 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 768 px (217ms)
  ✘  11 tests/responsive.spec.js:45:3 › nothing scrolls sideways at 390 px (290ms)

  12 passed (2.6s)
```

Agora os quatro workers são usados, porque há doze testes para entregar, e não três arquivos. A
opção também existe como `fullyParallel: true` numa configuração, para a execução inteira ou para
um projeto, e como `test.describe.configure({ mode: 'parallel' })` dentro de um arquivo. **Se os
testes de um arquivo podem rodar separados uns dos outros é um fato sobre aquele arquivo**, e por
isso o padrão os mantém juntos: um arquivo escrito como sequência, em que o segundo teste lê o que
o primeiro deixou, continua funcionando.

## A suíte inteira, de três jeitos

O projeto agora tem todos os arquivos de teste das aulas 1 a 18. Aqui está ele inteiro, cronometrado
pelo próprio Playwright, com um, dois e quatro workers nesta máquina de quatro processadores. O
`grep` guarda a linha que diz quantos workers rodaram e o resumo do final:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 1 worker
  61 passed (37.0s)
ana@laptop:~/quitanda$ npx playwright test --workers 2 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 2 workers
  3 failed
  1 did not run
  57 passed (28.1s)
ana@laptop:~/quitanda$ npx playwright test --workers 4 | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 4 workers
  3 failed
  58 passed (16.7s)
```

O tempo cai a cada worker acrescentado, de 37,0 segundos para 28,1 e depois 16,7. **E a execução
fica vermelha.** Com um worker todos os testes passaram; com dois e com quatro, três testes que usam
a loja falharam, e a aula 15 já encontrou o motivo. Dois workers é também o que um
`npx playwright test` simples usa aqui, então a execução padrão do projeto é a vermelha. A próxima
seção lê as falhas.
