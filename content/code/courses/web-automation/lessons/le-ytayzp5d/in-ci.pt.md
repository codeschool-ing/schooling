---
title: Guardando evidências num servidor de build
version: 1
---

No seu computador, evidência é uma conveniência. Num servidor de build ela é **a única coisa que
sobra**: a máquina que rodou os testes costuma ser descartada quando o job termina, e com ela todo
arquivo que a execução escreveu. O que você quiser ler sobre uma falha precisa ser copiado da
máquina antes disso. A aula 5 de `testing-cicd` trata do pipeline em si; esta seção trata do que a
execução dos testes deve deixar para ele guardar.

## Quando gravar, e quando guardar

As três opções compartilham uma família de valores, e eles diferem em **quando gravam** e **o que
guardam**. Estes quatro estão na documentação do Playwright tanto para `video` quanto para `trace`:

| valor | grava | guarda |
|---|---|---|
| `'off'` | nada | nada |
| `'on'` | todo teste | tudo |
| `'retain-on-failure'` | todo teste | só os testes que falharam |
| `'on-first-retry'` | só a primeira nova tentativa de um teste que falhou | essa tentativa |

O `screenshot` tem `'only-on-failure'` no lugar dos dois últimos, já que uma foto é tirada uma vez,
no fim. **`retain-on-failure` paga o custo de gravar em todo teste** e guarda só o necessário.
**`on-first-retry` não grava nada numa primeira execução**, e precisa de novas tentativas ligadas,
porque sem uma nova tentativa ele nunca grava. Aqui está ele com uma nova tentativa, no clique que
vem cedo demais:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/ssr.spec.js --retries 1 --trace on-first-retry

Running 1 test using 1 worker

  ✘  1 evidence/ssr.spec.js:10:1 › a click on /ssr, at once (5.7s)
  ✘  2 evidence/ssr.spec.js:10:1 › a click on /ssr, at once (retry #1) (5.8s)
ana@laptop:~/quitanda$ find test-results -type f | sort
test-results/.last-run.json
test-results/ssr-a-click-on-ssr-at-once-retry1/error-context.md
test-results/ssr-a-click-on-ssr-at-once-retry1/test-failed-1.png
test-results/ssr-a-click-on-ssr-at-once-retry1/trace.zip
test-results/ssr-a-click-on-ssr-at-once-retry1/video.webm
test-results/ssr-a-click-on-ssr-at-once/error-context.md
test-results/ssr-a-click-on-ssr-at-once/test-failed-1.png
test-results/ssr-a-click-on-ssr-at-once/video.webm
```

A primeira tentativa falhou e guardou a captura de tela e o vídeo, como a configuração pede, e
**nenhum rastro**: `on-first-retry` não grava uma primeira tentativa. A nova tentativa falhou do
mesmo jeito e deixou uma pasta própria, terminada em `-retry1`, com um rastro dentro. Isso é
barato, e tem um ponto cego. Um teste que falha uma vez e passa na nova tentativa é o que mais
precisa de diagnóstico, e com essa opção o único rastro que você tem dele é o da execução que
passou.

## Quanto custa

O custo em disco é fácil de medir. Três arquivos das aulas 1 a 3, seis testes, sem e depois com um
rastro para cada teste:

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js
  6 passed (7.8s)
ana@laptop:~/quitanda$ du -sh test-results
16K	test-results
```

```
ana@laptop:~/quitanda$ npx playwright test tests/smoke.spec.js tests/locators.spec.js tests/search.spec.js --trace on
  6 passed (7.9s)
ana@laptop:~/quitanda$ du -sh test-results; find test-results -name trace.zip | wc -l
344K	test-results
6
```

Sem rastros, os seis testes deixaram 16 KB, pouco mais que as próprias pastas. Com um rastro para
cada teste, deixaram 344 KB, cerca de 55 KB por teste, e as páginas desta loja são minúsculas. Um
rastro cresce com o que a página carrega e com cada ação, e a pasta do clique que falhou, com vídeo
e captura de tela, chegou sozinha a uns 270 KB. Multiplique por uma suíte e por cada execução de cada
branch, e `'on'` deixa de ser uma opção que alguém deixa ligada.

O outro custo é tempo. Os seis testes levaram 7.8 s sem rastros e 7.9 s com eles, uma execução de
cada, o que é pouco demais para dizer mais que *pequeno, aqui*. O vídeo não foi medido à parte. Uma
suíte de algumas centenas de testes paga o que ele custar algumas centenas de vezes, num servidor
de build que costuma ser uma máquina menor que um notebook.

## Onde as equipes costumam chegar

Uma escolha comum, e a que a configuração desta aula faz, é guardar tudo **só para os testes que
falharam**: `screenshot: 'only-on-failure'`, `trace: 'retain-on-failure'` e o vídeo em
`'retain-on-failure'` ou desligado, já que um rastro já guarda uma imagem de cada ação. A
configuração que o `npm init playwright` escreve para um projeto novo usa `trace: 'on-first-retry'`
com novas tentativas no servidor de build, o que é mais barato e só diagnostica falhas que
acontecem duas vezes.

Três hábitos fazem a evidência chegar a uma pessoa:

- **Copie `test-results/` e `playwright-report/` para fora da máquina, qualquer que seja o
  resultado.** Um passo que só roda no sucesso nunca roda quando importa, e esse passo é do
  pipeline.
- **Dê um prazo às cópias.** Os serviços de build apagam artefatos depois de um número de dias que
  você define; uma ou duas semanas cobrem o tempo entre uma falha e alguém olhar para ela, e limitam
  o disco.
- **Lembre o que um rastro contém.** Tudo o que a página mandou e recebeu está nele, cabeçalhos e
  corpos incluídos, então o rastro de um teste que fez login guarda o que o login trocou. Mantenha
  as contas de teste fictícias e os artefatos restritos à equipe.

A aula 19 roda a suíte em paralelo e a divide entre máquinas, e cada máquina deixa seu próprio
`test-results/`. A aula 14 trata de testes que falham só às vezes, em que a evidência da única
execução que falhou vale mais que qualquer número de execuções que passaram.
