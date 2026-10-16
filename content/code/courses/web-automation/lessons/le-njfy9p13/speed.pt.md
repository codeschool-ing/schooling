---
title: O headless é mais rápido?
version: 1
---

A afirmação de sempre é que headless é muito mais rápido, e ela é repetida como se fosse uma
medida. **É uma direção, e quanto ela vale depende de onde a suíte gasta o tempo.** Um navegador
sem janela deixa de pôr pixels numa tela; continua interpretando, rodando e diagramando cada
página, então a economia só pode vir da parte que a tela levava. O jeito de saber é cronometrar os
mesmos testes dos dois jeitos na mesma máquina.

## A suíte

Cinco arquivos de teste do projeto, das aulas 1, 2, 3, 5 e 6, rodados num só worker, para o
navegador iniciar uma vez e os testes rodarem um depois do outro. Uma execução inteira, para você
ver o que está sendo cronometrado:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js

Running 10 tests using 1 worker

  ✓   1 tests/locators.spec.js:7:1 › banana, by its test id (208ms)
  ✓   2 tests/locators.spec.js:12:1 › add a mango, by role and name (210ms)
  ✓   3 tests/locators.spec.js:18:1 › a price, and the space nobody can see (156ms)
  ✓   4 tests/search.spec.js:7:1 › one request: filling the box finds papaya (159ms)
  ✘   5 tests/search.spec.js:13:1 › typed key by key, the list settles on papaya (6.0s)
  ✓   6 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (167ms)
  ✓   7 tests/spa.spec.js:3:1 › Basket opens the basket without loading a page (317ms)
  ✓   8 tests/spa.spec.js:18:1 › Basket opens the basket on a slow network (1.1s)
  ✘   9 tests/spa.spec.js:30:1 › the basket opens from its own address (110ms)
  ✓  10 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.1s)

  10 passed (12.2s)
```

As duas linhas com `✘` são os testes que as aulas 3 e 5 mantêm com `test.fail()`, contados entre
os aprovados. O total da última linha é o que as próximas execuções comparam.

## Três modos, três vezes cada

O mesmo comando, no shell, no novo headless pelo `headless.config.js` e com janela sob o Xvfb,
repetido três vezes. O `tail -1` guarda a linha de resumo, que traz o total da execução:

```
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (12.1s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (14.2s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (15.4s)
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (12.5s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (14.7s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (15.1s)
ana@laptop:~/quitanda$ npx playwright test --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (13.5s)
ana@laptop:~/quitanda$ npx playwright test --config headless.config.js --project=new-headless --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (17.5s)
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed --workers 1 tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js tests/ssr.spec.js tests/spa.spec.js | tail -1
  10 passed (18.0s)
```

**Em todas as rodadas o shell foi o mais rápido e a execução com janela a mais lenta**, com o
novo headless no meio: 12,1, 14,2 e 15,4 segundos na primeira rodada, 12,5, 14,7 e 15,1 na segunda.
A terceira foi mais lenta em todos os modos, 13,5, 17,5 e 18,0, sem nada mudar na suíte, e é por
isso que uma medida se repete e se lê como um padrão, e não como um número.

**Quase toda a diferença está entre os dois programas, e não entre ter janela ou não.** O novo
headless é o mesmo navegador completo da execução com janela, e os tempos dele ficam perto dos dela:
1,2, 0,4 e 0,5 segundo de distância. O shell, o programa menor, fica dois a quatro segundos à frente
dos dois.

## Do que o número é feito

**A maior parte destes segundos é da loja, não do navegador.** O teste de busca espera respostas
lentas de propósito (aula 3), a página renderizada no servidor segura o script por um segundo e
meio (aula 6), e a falha esperada em `tests/search.spec.js` gasta o tempo limite inteiro antes de
contar como aprovada. Nada disso fica mais rápido sem janela. Uma suíte de mil testes curtos,
cada um abrindo uma página e clicando uma vez, gasta uma parte maior do tempo no navegador, e ali a
diferença seria maior. Uma suíte como esta, feita quase toda de esperas que ela quer ter, mal
percebe.

Duas outras coisas decidem o tempo muito mais que o modo. Os workers: a aula 19 roda estes arquivos
em paralelo, o que divide o total de um jeito que nenhum interruptor headless consegue. E a partida
do navegador: cada worker inicia um navegador, então uma suíte de muitos arquivos pequenos paga
esse custo uma vez por worker, e não uma vez por teste.

Então o argumento a favor do headless num servidor de build não é, na maior parte, velocidade. Ele
não precisa de tela, então não há nada a instalar nem nada a quebrar; e é o que o pipeline de todo
mundo roda, então uma falha ali é uma que alguém já viu. Rode com janela quando precisar da janela,
sob o Xvfb no servidor, e meça a sua própria suíte antes de acreditar no número de alguém, o desta
aula incluído.
