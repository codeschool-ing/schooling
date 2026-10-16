---
title: Comparando capturas de tela, em resumo
version: 1
---

Toda captura de tela até aqui foi evidência, tirada depois de uma falha para explicá-la. O
Playwright também usa uma captura como **a própria verificação**: tira uma foto da página, compara
com uma foto salva antes e falha quando elas diferem. A ideia atrai porque uma asserção cobre tudo o
que a página desenha, cores e espaçamentos incluídos, onde nenhum `toHaveText` chega. **É também a
verificação que mais falha por um motivo que não é defeito**, e esta seção mostra as duas metades.

## A referência é escrita pela primeira execução

`expect(page).toHaveScreenshot(name)` compara a página com uma foto guardada chamada **referência**
(*baseline*). Na primeira vez não há nenhuma, então a primeira execução escreve uma e falha. Salve
como `evidence/visual.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Fails once, on purpose: the first run has no picture to compare with,
// so it writes one and fails. Every run after compares against it.
test('the shop looks as it did', async ({ page, request }) => {
  await request.post('/api/reset');
  await page.goto('/');
  await expect(page.locator('#products li')).toHaveCount(8);
  await expect(page).toHaveScreenshot('shop.png');
});
```

O teste esvazia a cesta primeiro, porque o cabeçalho mostra a contagem e o total da cesta, e a foto
de uma cesta que outro teste encheu é outra foto. Ele espera os oito cartões pelo mesmo motivo: a
foto da lista antes de ela se encher seria a referência de coisa nenhuma.

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (660ms)


  1) evidence/visual.spec.js:5:1 › the shop looks as it did ────────────────────────────────────────

    Error: A snapshot doesn't exist at /home/ana/quitanda/evidence/visual.spec.js-snapshots/shop-linux.png, writing actual.

       7 |   await page.goto('/');
       8 |   await expect(page.locator('#products li')).toHaveCount(8);
    >  9 |   await expect(page).toHaveScreenshot('shop.png');
         |   ^
      10 | });
      11 |
        at /home/ana/quitanda/evidence/visual.spec.js:9:3

    attachment #1: shop (image/png) ────────────────────────────────────────────────────────────────
    Expected: evidence/visual.spec.js-snapshots/shop-linux.png
    Received: test-results/visual-the-shop-looks-as-it-did/shop-actual.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #2: screenshot (image/png) ──────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #3: video (video/webm) ──────────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/video.webm
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: test-results/visual-the-shop-looks-as-it-did/error-context.md

    attachment #5: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/trace.zip
    Usage:

        npx playwright show-trace test-results/visual-the-shop-looks-as-it-did/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    evidence/visual.spec.js:5:1 › the shop looks as it did ─────────────────────────────────────────

To open last HTML report run:

  npx playwright show-report
```

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js

Running 1 test using 1 worker

  ✓  1 evidence/visual.spec.js:5:1 › the shop looks as it did (470ms)

  1 passed (1.8s)

To open last HTML report run:

  npx playwright show-report

ana@laptop:~/quitanda$ ls -la evidence/visual.spec.js-snapshots/
total 60
drwxrwxr-x 2 ana ana  4096 Oct 15 22:11 .
drwxr-xr-x 3 ana ana  4096 Oct 15 22:11 ..
-rw-rw-r-- 1 ana ana 50966 Oct 15 22:11 shop-linux.png
```

A referência foi parar ao lado do teste, em `evidence/visual.spec.js-snapshots/`, com o nome
`shop-linux.png`: o Playwright acrescentou o sistema operacional ao nome, e acrescenta também o
nome do projeto quando a configuração tem projetos. A segunda execução comparou e passou. A
referência é um arquivo do projeto e vai para o controle de versão junto com o teste, porque uma
referência que mora numa máquina só é um teste que passa numa máquina só.

## Uma mudança que ela pega

Agora uma cor em `app/public/style.css` muda: a borda de cada cartão, de `#c9d6c3` para o verde
escuro da loja, `#2f6f4e`. Nada que um `toHaveText` lê se mexeu. O mesmo teste:

```
ana@laptop:~/quitanda$ npx playwright test --config evidence.config.js evidence/visual.spec.js

Running 1 test using 1 worker

  ✘  1 evidence/visual.spec.js:5:1 › the shop looks as it did (966ms)


  1) evidence/visual.spec.js:5:1 › the shop looks as it did ────────────────────────────────────────

    Error: expect(page).toHaveScreenshot(expected) failed

      4794 pixels (ratio 0.01 of all image pixels) are different.

      Snapshot: shop.png

    Call log:
      - Expect "toHaveScreenshot(shop.png)" with timeout 5000ms
        - verifying given screenshot expectation
      - taking page screenshot
        - disabled all CSS animations
      - waiting for fonts to load...
      - fonts loaded
      - 4794 pixels (ratio 0.01 of all image pixels) are different.
      - waiting 100ms before taking screenshot
      - taking page screenshot
        - disabled all CSS animations
      - waiting for fonts to load...
      - fonts loaded
      - captured a stable screenshot
      - 4794 pixels (ratio 0.01 of all image pixels) are different.


       7 |   await page.goto('/');
       8 |   await expect(page.locator('#products li')).toHaveCount(8);
    >  9 |   await expect(page).toHaveScreenshot('shop.png');
         |                      ^
      10 | });
      11 |
        at /home/ana/quitanda/evidence/visual.spec.js:9:22

    attachment #1: shop (image/png) ────────────────────────────────────────────────────────────────
    Expected: evidence/visual.spec.js-snapshots/shop-linux.png
    Received: test-results/visual-the-shop-looks-as-it-did/shop-actual.png
    Diff:     test-results/visual-the-shop-looks-as-it-did/shop-diff.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #2: screenshot (image/png) ──────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/test-failed-1.png
    ────────────────────────────────────────────────────────────────────────────────────────────────

    attachment #3: video (video/webm) ──────────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/video.webm
    ────────────────────────────────────────────────────────────────────────────────────────────────

    Error Context: test-results/visual-the-shop-looks-as-it-did/error-context.md

    attachment #5: trace (application/zip) ─────────────────────────────────────────────────────────
    test-results/visual-the-shop-looks-as-it-did/trace.zip
    Usage:

        npx playwright show-trace test-results/visual-the-shop-looks-as-it-did/trace.zip

    ────────────────────────────────────────────────────────────────────────────────────────────────

  1 failed
    evidence/visual.spec.js:5:1 › the shop looks as it did ─────────────────────────────────────────

To open last HTML report run:

  npx playwright show-report

ana@laptop:~/quitanda$ ls -la test-results/visual-*/
total 612
drwxrwxr-x 2 ana ana   4096 Oct 15 22:11 .
drwxrwxr-x 3 ana ana   4096 Oct 15 22:11 ..
-rw-rw-r-- 1 ana ana   1946 Oct 15 22:11 error-context.md
-rw-rw-r-- 1 ana ana  51000 Oct 15 22:11 shop-actual.png
-rw-rw-r-- 1 ana ana  57023 Oct 15 22:11 shop-diff.png
-rw-rw-r-- 1 ana ana  50966 Oct 15 22:11 shop-expected.png
-rw-rw-r-- 1 ana ana  51000 Oct 15 22:11 test-failed-1.png
-rw-rw-r-- 1 ana ana 343243 Oct 15 22:11 trace.zip
-rw-rw-r-- 1 ana ana  50155 Oct 15 22:11 video.webm
```

**4794 pixels diferem**: as bordas dos oito cartões. Isso é cerca de meio por cento dos 921.600
pixels de uma imagem de 1280 por 720, que a mensagem arredonda para uma proporção de 0.01. A falha
deixou três imagens além das evidências de sempre: `shop-expected.png`, a referência;
`shop-actual.png`, o que a página desenhou desta vez; e `shop-diff.png`, que marca onde elas
diferem. O registro de chamadas mostra também o Playwright tirando a captura duas vezes, com 100 ms
de intervalo, e só comparando depois que duas capturas seguidas concordaram entre si, para que uma
página ainda em movimento não falhe pelo movimento.

Esta execução é aquilo para que a verificação serve: uma mudança que nenhuma asserção de texto
veria, pega por uma linha. O estilo volta ao original depois, como toda mudança que este curso faz
na loja.

## Por que a foto em outra máquina é diferente

O texto é desenhado pelas fontes do sistema operacional. A loja pede `system-ui`, que é uma fonte
diferente no Ubuntu, no Windows e no macOS, e até duas máquinas Linux com fontes diferentes
instaladas desenham a mesma palavra um pixel mais larga ou mais estreita. O antisserrilhamento, a
borda suave em volta de cada letra, também muda entre drivers gráficos. **Uma referência escrita no
seu notebook e comparada num servidor de build pode falhar em toda linha de texto** sem nada de
errado na página. É por isso que o nome do arquivo leva `linux`: o Playwright guarda uma referência
por plataforma em vez de fingir que elas concordam.

Três coisas tornam a verificação utilizável, e cada uma tem um preço:

- **Comparar onde a referência foi feita.** Equipes rodam testes visuais só dentro de uma mesma
  imagem de contêiner, para que as fontes sejam sempre as mesmas; o preço é que rodar no notebook
  significa rodar o contêiner.
- **Tolerar um pouco.** O `toHaveScreenshot` aceita `maxDiffPixels` ou `maxDiffPixelRatio`, e um
  `threshold` para o quanto a cor de um pixel pode mudar antes de contar; o preço é que uma mudança
  menor que a tolerância passa.
- **Esconder o que muda sozinho.** A opção `mask` recebe localizadores e pinta por cima deles, para
  um relógio, um banner aleatório, um anúncio; o preço é que nada debaixo da máscara é verificado.

Quando uma mudança é intencional, `npx playwright test --update-snapshots` escreve referências
novas, e uma pessoa precisa olhar para elas antes do commit: uma execução de atualização aceita o
que a página desenhar, defeitos incluídos. Se um teste visual compensa essa manutenção, diante dos
defeitos que pegaria, é o tipo de julgamento de que trata a aula 22. Aqui basta saber que a
verificação existe e o que as falhas dela costumam significar.
