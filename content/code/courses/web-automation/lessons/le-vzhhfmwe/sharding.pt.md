---
title: Shards: uma suíte em várias máquinas
version: 1
---

Os workers dividem uma máquina, então dividem os processadores e a memória dela, e a última seção
desta aula mede onde isso se esgota. **Um shard é o outro jeito de dividir uma suíte: uma fatia dos
testes, rodada numa máquina só dela.** `--shard=1/3` quer dizer "o primeiro terço"; três tarefas de
CI rodam `--shard=1/3`, `--shard=2/3` e `--shard=3/3`, cada uma com o próprio checkout, a própria
loja aberta pelo `webServer` e os próprios workers. A aula 5 de `testing-cicd` trata de como um
serviço de CI abre três tarefas ao mesmo tempo; o que segue é o que o Playwright faz dentro de cada
uma.

## Como as fatias são cortadas

A crença a largar primeiro é que o Playwright equilibra os shards pelo tempo. Ele não sabe quanto um
teste leva antes de rodá-lo. A regra está em `node_modules/playwright/lib/runner/testGroups.js`,
numa função chamada `filterForShard`, e ela conta **testes**. A suíte é primeiro cortada em grupos,
os mesmos grupos entregues aos workers: um arquivo inteiro, a menos que o arquivo seja totalmente
paralelo, caso em que cada teste é um grupo. Depois os grupos são distribuídos em ordem, e um grupo
vai para o shard onde cai o primeiro teste dele quando o total é dividido por três. **Um arquivo
nunca é partido entre shards**, porque um grupo nunca é partido.

Pedir a lista de cada shard mostra o corte sem rodar nada:

```
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=1/3 | tail -1
Total: 42 tests in 17 files
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=2/3 | tail -1
Total: 40 tests in 16 files
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --list --shard=3/3 | tail -1
Total: 39 tests in 18 files
```

Sessenta e um testes dão uns vinte por shard, e estes shards têm 42, 40 e 39. A próxima seção
mostra de onde veio a sobra.

## Shards e fases não se misturam

Aqui as três fatias rodam uma depois da outra no mesmo notebook, fazendo o papel de três máquinas.
Cada uma também grava um **relatório blob**, um arquivo zip com tudo o que o reporter viu, para que
os três possam virar um relatório depois; num CI de verdade, cada tarefa envia o zip dela e uma
última tarefa os junta. O `--reporter=list,blob` mantém a lista na tela e grava o zip em
`blob-report/`. O reporter blob esvazia essa pasta ao começar, então cada zip é movido para fora
depois da execução:

```
ana@laptop:~/quitanda$ mkdir -p all-blob-reports
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 42 tests using 2 workers, shard 1 of 3
  42 passed (19.0s)
ana@laptop:~/quitanda$ mv blob-report/report-1.zip all-blob-reports/
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 40 tests using 2 workers, shard 2 of 3
  40 passed (11.7s)
ana@laptop:~/quitanda$ mv blob-report/report-2.zip all-blob-reports/
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 39 tests using 2 workers, shard 3 of 3
  39 passed (21.3s)
ana@laptop:~/quitanda$ mv blob-report/report-3.zip all-blob-reports/
```

```
ana@laptop:~/quitanda$ npx playwright merge-reports --reporter list all-blob-reports | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 121 tests using 6 workers
  121 passed (21.3s)
```

**O relatório juntado conta 121 testes, e a suíte tem 61.** Cada shard rodou os trinta testes do
`parallel` inteiros e só a própria fatia do `one-at-a-time`: 30 e 12, 30 e 10, 30 e 9. É isso que
`dependencies` quer dizer, e o `node_modules/playwright/lib/runner/loadUtils.js` faz isso de
propósito: depois que o filtro de shards escolheu uma fatia, todo projeto de que um projeto escolhido
depende volta inteiro. Para um projeto de preparação que faz login, rodá-lo em toda máquina é
exatamente o certo. Para o `parallel`, que é metade da suíte, quer dizer que toda máquina roda essa
metade de novo, e o shard mais lento levou 21,3 segundos, boa parte em trabalho repetido.

## Um comando por fase

A saída é impedir o Playwright de acrescentar a dependência de volta: em cada máquina, rodar os dois
projetos como dois comandos, cada um com o mesmo `--shard`. O `--project` escolhe um projeto, e o
`--no-deps` diz ao Playwright para não rodar as dependências dele. Isso é seguro aqui porque o
`one-at-a-time` nunca precisou de nada que o `parallel` fez; a dependência só existia para manter os
dois separados no tempo, e dois comandos seguidos já fazem isso. Os zips são renomeados ao serem
movidos, porque os dois comandos de um shard gravam um arquivo com o mesmo nome:

```
ana@laptop:~/quitanda$ rm -rf all-blob-reports && mkdir all-blob-reports
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 10 tests using 2 workers, shard 1 of 3
  10 passed (2.2s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-1.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=1/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 12 tests using 1 worker, shard 1 of 3
  12 passed (10.7s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-1.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 11 tests using 2 workers, shard 2 of 3
  11 passed (8.1s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-2.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=2/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 10 tests using 1 worker, shard 2 of 3
  10 passed (3.7s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-2.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project parallel --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 9 tests using 2 workers, shard 3 of 3
  9 passed (3.5s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/parallel-3.zip
ana@laptop:~/quitanda$ npx playwright test --config turns.config.js --project one-at-a-time --no-deps --shard=3/3 --reporter=list,blob | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 9 tests using 1 worker, shard 3 of 3
  9 passed (13.0s)
ana@laptop:~/quitanda$ mv blob-report/*.zip all-blob-reports/one-at-a-time-3.zip
```

```
ana@laptop:~/quitanda$ npx playwright merge-reports --reporter list all-blob-reports | grep -E '^Running|^  [0-9]+ (passed|failed|flaky|skipped|did not run)'
Running 61 tests using 9 workers
  61 passed (13.0s)
```

Sessenta e um testes, cada um rodado uma vez: 10 e 12 na primeira máquina, 11 e 10 na segunda, 9 e
9 na terceira. O tempo que o `merge-reports` imprime é o da execução mais longa que recebeu, não um
total. Nas próprias máquinas os dois comandos levaram 12,9, 11,8 e 16,5 segundos, mais a partida de
um segundo comando, contra 19,0, 11,7 e 21,3 antes. E onze testes levaram 8,1 segundos onde dez
levaram 2,2: uma contagem de testes não diz nada sobre o tempo.

**Um shard dura o que duram os testes que caíram nele**, e a execução inteira dura o que dura a
máquina mais lenta, porque o relatório juntado espera as três. Duas coisas decidem a diferença. Um
arquivo é distribuído inteiro, então um arquivo com um teste lento arrasta o shard todo; e os
testes que esperam cinco segundos de propósito, entre eles os de `test.fail()` das aulas 3 e 4,
caem onde o arquivo deles cair. Quando um shard é sempre o mais lento, a correção é partir o arquivo
que o deixa lento, ou marcá-lo como totalmente paralelo para os testes serem distribuídos
separados.

Cada shard rodou a própria loja, e esse é o único ponto em que os shards ajudam com o antagonista
desta aula: duas máquinas nunca dividem uma cesta. Dentro de cada shard, os workers ainda dividem
uma loja, e é por isso que o projeto um-de-cada-vez continua lá.
