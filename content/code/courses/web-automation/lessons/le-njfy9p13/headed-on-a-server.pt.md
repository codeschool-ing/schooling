---
title: Uma janela numa máquina sem tela
version: 1
---

Headless é o que um servidor de build roda, e para a maioria das suítes é a escolha certa. **Há
casos em que um teste precisa de uma janela de verdade numa máquina sem tela**, e eles são de três
tipos:

- **um defeito que só aparece com janela.** Foco, uma janela que a página redimensiona, um pop-up
  que o site abre, tudo o que depende da moldura do próprio navegador em volta da página. Um teste
  que passa headless e falha para uma pessoa é indício desse caso; rodá-lo com janela no servidor
  é como reproduzi-lo lá;
- **algo que o shell não faz.** A documentação do Playwright diz que extensões de navegador
  precisam do Chromium completo; o teste de uma extensão roda com janela, ou no novo headless com
  `channel: 'chromium'`;
- **o mesmo navegador que seus usuários rodam.** Uma suíte que quer medir o que as pessoas recebem,
  e não uma aproximação headless disso, roda com a janela ligada.

## Uma tela que não existe

No Linux, os programas desenham janelas conversando com um servidor de vídeo. **O Xvfb é um
servidor de vídeo que desenha na memória**: aceita janelas como qualquer outro, e ninguém as vê. O
`xvfb-run` inicia um, aponta a variável `DISPLAY` para ele, roda o seu comando e o para de novo. No
Ubuntu ele vem do repositório:

```sh
sudo apt-get install xvfb
```

A máquina em que estas aulas foram gravadas já tinha o pacote do Ubuntu, então a instalação não
aparece:

```
ana@laptop:~/quitanda$ dpkg -s xvfb | grep ^Version
Version: 2:21.1.12-1ubuntu1.8
```

Sem ele, um teste com janela falha antes da primeira linha. O executor de testes mostra a mesma
caixa que o `modes.mjs` mostrou:

```
ana@laptop:~/quitanda$ npx playwright test --headed tests/smoke.spec.js 2>&1 | head -14

Running 1 test using 1 worker

  ✘  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (5ms)


  1) tests/smoke.spec.js:3:1 › the shop opens and lists its fruit ──────────────────────────────────

    Error: browserType.launch: Target page, context or browser has been closed
    Browser logs:

    ╔════════════════════════════════════════════════════════════════════════════════════════════════╗
    ║ Looks like you launched a headed browser without having a XServer running.                     ║
    ║ Set either 'headless: true' or use 'xvfb-run <your-playwright-app>' before running Playwright. ║
```

Com `xvfb-run` na frente do mesmo comando, o navegador tem a sua tela e o teste passa:

```
ana@laptop:~/quitanda$ xvfb-run npx playwright test --headed tests/smoke.spec.js

Running 1 test using 1 worker

  ✓  1 tests/smoke.spec.js:3:1 › the shop opens and lists its fruit (603ms)

  1 passed (2.2s)
```

**Nada no teste nem na configuração mudou**; só o ambiente em que o navegador iniciou.

## O tamanho de uma tela que ninguém vê

Rode `modes.mjs headed` por ele e a janela que o Chromium abre volta a ter o tamanho de uma tela:

```
ana@laptop:~/quitanda$ xvfb-run node modes.mjs headed
headed 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  webdriver: true,
  ownWindow: '1050x917',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

O user agent perdeu a palavra `HeadlessChrome`: é o `Chrome/141.0.0.0` simples, o navegador com
janela. A janela tem 1050 por 917. O `xvfb-run` cria uma tela de 1280 por 1024 se ninguém disser
outra coisa, e o Chromium dimensiona a primeira janela pela tela que encontra. Outra tela, dada com
`-s`, dá outra janela:

```
ana@laptop:~/quitanda$ xvfb-run -s "-screen 0 1920x1080x24" node modes.mjs headed
headed 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  webdriver: true,
  ownWindow: '945x973',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

**O viewport não se mexeu**: 1280 por 720 nos dois, porque o Playwright o fixa na página, seja qual
for a janela. O Selenium não fixa nada, então a página dele é a janela, e a janela segue a tela:

```
ana@laptop:~/quitanda$ xvfb-run node selenium/headless.mjs
[
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36',
  '1050x865',
  'Weekly deals, in a table.'
]
```

Duas notas práticas da própria ajuda do `xvfb-run`. Ele usa a tela de número 99 se ninguém disser
outra coisa, então dois comandos iniciados ao mesmo tempo numa máquina pedem a mesma tela; o
`xvfb-run -a` procura um número livre. E o tamanho e a profundidade de cor da tela merecem ir
escritos no comando, como o `-s "-screen 0 1920x1080x24"` acima, porque um padrão que você não
escolheu é um padrão que outra pessoa pode mudar.
