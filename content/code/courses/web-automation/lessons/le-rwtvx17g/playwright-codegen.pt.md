---
title: O gravador do próprio Playwright
version: 1
---

O Playwright traz um gravador no mesmo pacote que você instalou na aula 1. `npx playwright codegen
http://localhost:3000/` abre um navegador ao lado de uma janela chamada Inspector, e cada clique que
você dá no navegador aparece no Inspector como uma linha de código Playwright. **Ele não foi rodado
neste curso, porque as duas janelas precisam de uma tela.** Duas partes dele rodam sem tela, e
dizem quase tudo o que importa: as opções, e a função que ele chama para nomear um elemento.

## As opções

```
ana@laptop:~/quitanda$ npx playwright codegen --help
Usage: npx playwright codegen [options] [url]

open page and generate code for user actions

Options:
  -o, --output <file name>             saves the generated script to a file
  --target <language>                  language to generate, one of javascript,
                                       playwright-test, python, python-async,
                                       python-pytest, csharp, csharp-mstest,
                                       csharp-nunit, java, java-junit (default:
                                       "playwright-test")
  --test-id-attribute <attributeName>  use the specified attribute to generate
                                       data test ID selectors
  -b, --browser <browserType>          browser to use, one of cr, chromium, ff,
                                       firefox, wk, webkit (default: "chromium")
  --block-service-workers              block service workers
  --channel <channel>                  Chromium distribution channel, "chrome",
                                       "chrome-beta", "msedge-dev", etc
  --color-scheme <scheme>              emulate preferred color scheme, "light"
                                       or "dark"
  --device <deviceName>                emulate device, for example  "iPhone 11"
  --geolocation <coordinates>          specify geolocation coordinates, for
                                       example "37.819722,-122.478611"
  --ignore-https-errors                ignore https errors
  --load-storage <filename>            load context storage state from the file,
                                       previously saved with --save-storage
  --lang <language>                    specify language / locale, for example
                                       "en-GB"
  --proxy-server <proxy>               specify proxy server, for example
                                       "http://myproxy:3128" or
                                       "socks5://myproxy:8080"
  --proxy-bypass <bypass>              comma-separated domains to bypass proxy,
                                       for example
                                       ".com,chromium.org,.domain.com"
  --save-har <filename>                save HAR file with all network activity
                                       at the end
  --save-har-glob <glob pattern>       filter entries in the HAR by matching url
                                       against this glob pattern
  --save-storage <filename>            save context storage state at the end,
                                       for later use with --load-storage
  --timezone <time zone>               time zone to emulate, for example
                                       "Europe/Rome"
  --timeout <timeout>                  timeout for Playwright actions in
                                       milliseconds, no timeout by default
  --user-agent <ua string>             specify user agent string
  --user-data-dir <directory>          use the specified user data directory
                                       instead of a new context
  --viewport-size <size>               specify browser viewport size in pixels,
                                       for example "1280, 720"
  -h, --help                           display help for command

Examples:

  $ codegen
  $ codegen --target=python
  $ codegen -b webkit https://example.com
```

Três opções dessa lista importam mais do que as outras. `--target` escolhe a linguagem do código, e
o padrão, `playwright-test`, são os arquivos de teste que este curso escreve. `--test-id-attribute`
diz qual atributo conta como test id, para uma aplicação que o escreve diferente de `data-testid`.
E `-o` salva o que ele escreveu num arquivo quando a gravação termina, em vez de deixar no
Inspector para você copiar.

## Perguntando como ele nomearia a loja

Quando você clica num elemento durante uma gravação, o codegen pergunta a uma função de dentro do
Playwright como chamar aquele elemento, e escreve a resposta na linha. A mesma função pode ser
consultada direto: com a variável de ambiente `PWDEBUG=console`, o Playwright põe um objeto chamado
`playwright` em toda página que abre, e o método `generateLocator` dele devolve o nome de um
elemento que você entrega. No `playwright-core` 1.56.0 os dois passam pelo mesmo código de
`generateSelector`, então as respostas abaixo são os nomes que o codegen escreveria.

Este script abre a loja, acha doze elementos por um seletor CSS próprio e pergunta ao gerador como
ele chamaria cada um. Salve-o como `pick.mjs`:

```javascript
import { chromium } from '@playwright/test';

const browser = await chromium.launch();
const page = await browser.newPage();
await page.goto('http://localhost:3000/');
await page.locator('#products[aria-busy="false"]').waitFor();

// Each element is found here by a stable CSS selector, then Playwright's
// generator is asked what IT would call that element.
const fruit = ['banana', 'mango', 'papaya', 'guava', 'cashew', 'passion', 'acerola', 'pineapple'];
const elements = [
  ...fruit.map((id) => `[data-testid=product-${id}] button`),
  '[data-testid=product-banana] h2',
  '[data-testid=basket-count]',
  '.basket-total',
  '.toast',
];
for (const css of elements) {
  const name = await page.evaluate(
    (s) => playwright.generateLocator(document.querySelector(s)),
    css,
  );
  console.log(css.padEnd(38), name);
}
await browser.close();
```

Suba a loja com `npm start` num terminal e rode o script duas vezes em outro. No Windows, no
PowerShell, defina a variável antes com `$env:PWDEBUG = 'console'` e rode `node pick.mjs`.

```
ana@laptop:~/quitanda$ PWDEBUG=console node pick.mjs
[data-testid=product-banana] button    getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
[data-testid=product-mango] button     getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
[data-testid=product-papaya] button    getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
[data-testid=product-guava] button     getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
[data-testid=product-cashew] button    getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
[data-testid=product-passion] button   getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
[data-testid=product-acerola] button   locator('#card-3585 > button')
[data-testid=product-pineapple] button locator('#card-3215 > button')
[data-testid=product-banana] h2        getByRole('heading', { name: 'Banana' })
[data-testid=basket-count]             getByTestId('basket-count')
.basket-total                          getByText('R$ 0,00')
.toast                                 getByRole('status')
ana@laptop:~/quitanda$ PWDEBUG=console node pick.mjs
[data-testid=product-banana] button    getByTestId('product-banana').getByRole('button', { name: 'Add to basket' })
[data-testid=product-mango] button     getByTestId('product-mango').getByRole('button', { name: 'Add to basket' })
[data-testid=product-papaya] button    getByTestId('product-papaya').getByRole('button', { name: 'Add to basket' })
[data-testid=product-guava] button     getByTestId('product-guava').getByRole('button', { name: 'Add to basket' })
[data-testid=product-cashew] button    getByTestId('product-cashew').getByRole('button', { name: 'Add to basket' })
[data-testid=product-passion] button   getByTestId('product-passion').getByRole('button', { name: 'Add to basket' })
[data-testid=product-acerola] button   locator('#card-8452 > button')
[data-testid=product-pineapple] button locator('#card-5129 > button')
[data-testid=product-banana] h2        getByRole('heading', { name: 'Banana' })
[data-testid=basket-count]             getByTestId('basket-count')
.basket-total                          getByText('R$ 0,00')
.toast                                 getByRole('status')
```

**A maioria das respostas é a que a aula 2 recomendou.** O título é nomeado pelo papel e pelo texto,
o aviso pelo papel, a contagem pelo test id, e seis dos botões pelo test id do cartão e pelo papel
e nome do botão. Uma gravação desses cliques ficaria perto do teste que você escreveria à mão.

**Duas respostas estão erradas, e são as mesmas duas nas duas execuções.** Os botões da acerola e
do abacaxi, o sétimo e o oitavo de oito botões idênticos, são nomeados pelo `id` aleatório do
cartão, e o número muda entre as execuções porque a página o sorteou de novo. É a divisão que o erro
de modo estrito da aula 2 mostrou para os mesmos botões: seis nomeados pelo test id, os dois últimos
por `#card-NNNN`. Por que o gerador muda de ideia no sétimo é coisa da pontuação interna dele, e
este curso não a desmontou. O que um testador precisa é do fato de que ele muda, toda vez.

**Uma resposta está certa hoje e errada depois do primeiro clique.** O total não tem papel, nem
rótulo, nem test id, então o gerador o nomeou pelo texto que mostrava, `getByText('R$ 0,00')`.
Depois que uma banana entra na cesta o total diz `R$ 5,90`, e esse localizador não acha nada. Um
gravador nomeia um elemento pelo que ele é no momento em que você aponta, e o total é o único
elemento da loja cuja função inteira é mudar.

## Como fica um teste gravado

O codegen escreve um arquivo inteiro por sessão. O gerador de JavaScript dele, na mesma versão,
começa todo arquivo com uma importação de `test` e `expect` e um teste chamado `test`, escreve por
extenso o endereço que você digitou e transforma o "assert text" do Inspector em `toContainText`.
Uma sessão que põe uma banana e confere a contagem sairia neste formato; ele foi escrito para esta
aula a partir desse código-fonte, não salvo pelo codegen:

```javascript
import { test, expect } from '@playwright/test';

test('test', async ({ page }) => {
  await page.goto('http://localhost:3000/');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toContainText('1');
});
```

**Ele é melhor que a gravação do Selenium IDE num ponto que importa.** A asserção é das que esperam
pela página, o tipo que a aula 11 comparou com o Puppeteer: pergunta de novo até a contagem dizer
`1` ou cinco segundos passarem, então a gravação dispensa pausa. Continua sendo uma transcrição.
Nada esvazia a cesta antes do clique, o endereço por extenso ignora o `baseURL` do
`playwright.config.js`, o teste se chama `test`, e a próxima sessão vai repetir as mesmas três
linhas num arquivo próprio.
