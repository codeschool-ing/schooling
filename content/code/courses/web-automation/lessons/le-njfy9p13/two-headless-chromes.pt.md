---
title: Dois Chromiums headless
version: 1
---

A imagem óbvia é a de um navegador com um interruptor: janela ligada, janela desligada. **Para o
Chromium essa imagem está desatualizada, e o Playwright instala dois programas separados para os
dois modos.** O modo headless do Chrome começou como uma segunda implementação, menor, embutida no
mesmo programa, que dividia o motor mas não o navegador em volta dele. Depois o Chrome refez o
headless como o navegador de verdade com a janela desligada, e tirou o antigo. Peça o modo antigo
ao Chrome 141 e ele mesmo diz:

```
ana@laptop:~/quitanda$ google-chrome --headless=old --dump-dom http://localhost:3000/deals
Old Headless mode has been removed from the Chrome binary. Please use the new Headless mode (https://developer.chrome.com/docs/chromium/new-headless) or the chrome-headless-shell which is a standalone implementation of the old Headless mode (https://developer.chrome.com/blog/chrome-headless-shell).
```

O **novo headless** é o navegador inteiro sem janela. O **headless shell** é a implementação
antiga, mantida viva como um programa separado e menor, para automação. Os dois são o Chromium 141
aqui, e os dois atendem a `headless: true`, então a pergunta é qual deles o Playwright inicia.

## Que programa roda

O Playwright imprime o comando que lança quando a variável `DEBUG` cita `pw:browser`. A linha tem
centenas de caracteres; o `grep -o` guarda o caminho do programa:

```
ana@laptop:~/quitanda$ DEBUG=pw:browser node modes.mjs shell 2>&1 | grep -o "<launching> [^ ]*"
<launching> /home/ana/.cache/ms-playwright/chromium_headless_shell-1194/chrome-linux/headless_shell
ana@laptop:~/quitanda$ DEBUG=pw:browser node modes.mjs new 2>&1 | grep -o "<launching> [^ ]*"
<launching> /home/ana/.cache/ms-playwright/chromium-1194/chrome-linux/chrome
```

**Headless sem channel inicia o shell; `channel: 'chromium'` inicia o navegador completo no novo
headless.** O navegador completo é também o que roda sempre que há janela, e isso faz dele o único
dos dois capaz de rodar com `--headed`. Os dois estão no cache do Playwright, e o shell tem mais
ou menos metade do tamanho:

```
ana@laptop:~/quitanda$ du -sh ~/.cache/ms-playwright/*
597M	/home/ana/.cache/ms-playwright/chromium-1194
323M	/home/ana/.cache/ms-playwright/chromium_headless_shell-1194
4.9M	/home/ana/.cache/ms-playwright/ffmpeg-1011
```

O `npx playwright install chromium` baixa os dois. Duas opções escolhem um deles:

```
ana@laptop:~/quitanda$ npx playwright install --help | head -12
Usage: npx playwright install [options] [browser...]

ensure browsers necessary for this version of Playwright are installed

Options:
  --with-deps   install system dependencies for browsers
  --dry-run     do not execute installation, only print information
  --list        prints list of browsers from all playwright installations
  --force       force reinstall of stable browser channels
  --only-shell  only install headless shell when installing chromium
  --no-shell    do not install chromium headless shell
  -h, --help    display help for command
```

Um servidor de build que só roda headless com a configuração padrão pode usar `--only-shell` e
poupar o download maior. Uma máquina que roda com janela, ou usa `channel: 'chromium'`, precisa do
navegador completo, que é o que o `--no-shell` mantém.

## O que um site consegue distinguir

Rode o `modes.mjs` com `new`, o navegador completo no novo headless:

```
ana@laptop:~/quitanda$ node modes.mjs new
new 141.0.7390.37 {
  userAgent: 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/141.0.0.0 Safari/537.36',
  webdriver: true,
  ownWindow: '780x493',
  viewport: '1280x720',
  deals: 'Weekly deals, in a table.'
}
```

A mesma versão, `141.0.7390.37`, e três respostas diferentes das do shell:

| | headless shell | novo headless |
|---|---|---|
| a versão no user agent | `HeadlessChrome/141.0.7390.37` | `HeadlessChrome/141.0.0.0` |
| a janela que ele inventa | 800 por 600 | 780 por 493 |
| a página que um teste recebe | 1280 por 720 | 1280 por 720 |

O número de versão mais curto é o user agent reduzido do próprio navegador completo, a forma que o
Chrome manda quando tem janela também; o shell ainda manda todos os dígitos. **Os dois continuam
dizendo `HeadlessChrome`**, então um site que procura essa palavra a encontra em qualquer dos dois
modos. A linha do viewport é a que tranquiliza: os 1280 por 720 do Playwright são iguais nos dois,
então um teste que não mexe nele vê a mesma página. As janelas inventadas só importam para um teste
que desliga o viewport, e a seção sobre as diferenças que mordem é esse teste.

Para rodar os testes do projeto em cada um, uma segunda configuração acrescenta dois projetos, do
jeito que o `browsers.config.js` da aula 10 acrescentou três navegadores. Salve-a como
`headless.config.js`:

```javascript
import { defineConfig } from '@playwright/test';
import base from './playwright.config.js';

// The project's own settings, run in Playwright's two headless Chromiums.
export default defineConfig(base, {
  projects: [
    { name: 'shell', use: { headless: true } },
    { name: 'new-headless', use: { headless: true, channel: 'chromium' } },
  ],
});
```

## O Selenium pede direto ao Chrome

O Selenium não tem opção headless própria. Ele inicia o Chrome pelo chromedriver com os argumentos
que você der, e `--headless=new` é o interruptor do Chrome, como o primeiro teste da aula 8 usou.
Este script abre a página de ofertas e informa as mesmas três coisas; salve-o como
`selenium/headless.mjs`:

```javascript
import { Builder } from 'selenium-webdriver';
import chrome from 'selenium-webdriver/chrome.js';

// node selenium/headless.mjs [--headless=new]; the shop must be running.
const options = new chrome.Options();
if (process.argv[2]) options.addArguments(process.argv[2]);
const driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
try {
  await driver.get('http://localhost:3000/deals');
  console.log(await driver.executeScript(
    'return [navigator.userAgent, innerWidth + "x" + innerHeight, document.querySelector("p").textContent]'));
} finally {
  await driver.quit();
}
```

```
ana@laptop:~/quitanda$ node selenium/headless.mjs --headless=new
[
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/141.0.0.0 Safari/537.36',
  '780x441',
  'Weekly deals, in a table.'
]
ana@laptop:~/quitanda$ node selenium/headless.mjs --headless
[
  'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/141.0.0.0 Safari/537.36',
  '780x441',
  'Weekly deals, in a table.'
]
```

**`--headless` sozinho e `--headless=new` são o mesmo modo agora**, o navegador completo, porque o
outro acabou. A janela tem 780 de largura, como no novo headless do Playwright, e nada fixa um
viewport para ela: o Selenium dá à página a janela que o Chrome abriu, e esse é um dos motivos de
suítes Selenium fixarem o tamanho da janela por conta própria. Guias antigos ainda dizem
`--headless=old`, e isto é o que custa hoje:

```
ana@laptop:~/quitanda$ node selenium/headless.mjs --headless=old 2>&1 | grep Error:
SessionNotCreatedError: session not created: probably user data directory is already in use, please specify a unique value for --user-data-dir argument, or don't use --user-data-dir
```

**A mensagem culpa um diretório de dados do usuário, e a causa é outra.** O Chrome recusou o modo e
encerrou, e o chromedriver, que só viu um navegador que nunca respondeu, chutou. Quando o erro de
um driver não combina com o que você fez, inicie o navegador à mão com os mesmos argumentos, como
a primeira transcrição desta seção fez; a mensagem do próprio Chrome disse a causa numa linha.
