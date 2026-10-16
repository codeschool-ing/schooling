---
title: Páginas adaptativas, escolhidas pelo servidor
version: 1
---

Um site **adaptativo** toma a decisão antes de a página sair do servidor. Ele lê o cabeçalho
`User-Agent` da requisição, o nome que o navegador dá a si mesmo, adivinha que tipo de aparelho a
mandou e envia uma de duas ou mais páginas diferentes. Uma página responsiva é o mesmo HTML em toda
parte e quem decide é a folha de estilos; uma página adaptativa é outro HTML, e **a largura da
janela não decide nada**, porque nada na requisição diz a este servidor qual ela é.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"Duas caixas. O navegador guarda a largura da janela, 390, e a string User-Agent. Só o User-Agent atravessa uma seta até o servidor, enviado com toda requisição; a largura não é enviada. Páginas responsivas decidem no navegador, páginas adaptativas no servidor.\"><rect x=\"20\" y=\"30\" width=\"300\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"36\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">o navegador</text><rect x=\"36\" y=\"72\" width=\"268\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"48\" y=\"99\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a largura da janela, 390</text><rect x=\"36\" y=\"128\" width=\"268\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"48\" y=\"155\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\">User-Agent: …Mobile…</text><text x=\"36\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">páginas responsivas decidem aqui</text><text x=\"385\" y=\"99\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a largura não é enviada</text><path d=\"M306 150 L440 150\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M448 150 L438 144 L438 156 Z\" fill=\"var(--phosphor)\"></path><text x=\"385\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">enviado em toda requisição</text><rect x=\"450\" y=\"30\" width=\"250\" height=\"190\" rx=\"8\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"466\" y=\"56\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">o servidor</text><rect x=\"466\" y=\"128\" width=\"218\" height=\"44\" rx=\"4\" fill=\"var(--scan)\"></rect><text x=\"478\" y=\"155\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">lê e escolhe uma página</text><text x=\"466\" y=\"203\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">páginas adaptativas decidem aqui</text></svg>", "caption": "Cada tipo de página decide com o que consegue ver. O servidor da loja nunca fica sabendo a largura, então nenhum tamanho de janela testa uma página adaptativa."}
```

## A página de ofertas

A página de ofertas da loja é adaptativa do jeito mais simples possível: duas páginas, um teste
sobre uma string. Salve-o como `app/routes/deals.js`:

```javascript
import { send } from '../http.js';

// Adaptive: the server picks one of two pages from the User-Agent header.
// A narrow window on a desktop browser still gets the desktop page.
export const routes = [
  {
    method: 'GET', path: '/deals',
    handle: ({ req, res }) => {
      const phone = /Mobile/.test(req.headers['user-agent'] ?? '');
      const body = phone
        ? '<!doctype html><title>Deals</title><h1>Deals</h1><p>Tap a deal to call the shop.</p>'
        : '<!doctype html><title>Deals</title><h1>Deals</h1><p>Weekly deals, in a table.</p>';
      send(res, 200, body, { 'Content-Type': 'text/html; charset=utf-8', Vary: 'User-Agent' });
    },
  },
];
```

O servidor lê todos os arquivos de `app/routes/` ao iniciar, então reinicie a loja. Uma requisição
do `curl`, que se chama de `curl` e um número de versão, recebe a página de computador:

```
ana@laptop:~/quitanda$ curl -si http://localhost:3000/deals
HTTP/1.1 200 OK
Content-Type: text/html; charset=utf-8
Vary: User-Agent
Date: Sat, 10 Oct 2026 19:36:08 GMT
Connection: keep-alive
Keep-Alive: timeout=5
Transfer-Encoding: chunked

<!doctype html><title>Deals</title><h1>Deals</h1><p>Weekly deals, in a table.</p>
```

e a mesma requisição com o nome do iPhone 13, lido do descritor do Playwright, recebe a outra:

```
ana@laptop:~/quitanda$ curl -s -A "$(node -p "require('@playwright/test').devices['iPhone 13'].userAgent")" http://localhost:3000/deals
<!doctype html><title>Deals</title><h1>Deals</h1><p>Tap a deal to call the shop.</p>
```

**Mesmo endereço, mesmo servidor, outra página**, escolhida pela palavra `Mobile` em algum ponto de
uma string. A seção sobre a viewport mostrou a outra metade: uma janela de computador com 390 pixels
recebeu *Weekly deals, in a table*, e o descritor do iPhone na mesma largura recebeu *Tap a deal to
call the shop*. Estreitar uma janela, que é todo o teste de uma página responsiva, não testa uma
página adaptativa em nada.

## `Vary`, o cabeçalho que mantém as duas separadas

Olhe de novo os cabeçalhos: `Vary: User-Agent`. Ele avisa todo cache entre o servidor e o navegador
que esta resposta depende daquele cabeçalho da requisição, então uma cópia guardada para um
`User-Agent` não pode ser entregue a outro. Sem ele, um cache que guardou a página de celular
poderia servi-la ao próximo computador que pedisse, e o defeito iria e viria conforme quem pediu
primeiro. A aula 4 trata de caches; numa página adaptativa, o cabeçalho `Vary` faz parte do que
verificar.

## O teste, e um erro que vale conhecer

Uma primeira tentativa põe o descritor num bloco `describe`, como a seção anterior pôs cada largura.
Salve-o como `tests/deals.spec.js`:

```javascript
import { test, expect, devices } from '@playwright/test';

test.describe('an iPhone', () => {
  test.use(devices['iPhone 13']);

  test('gets the page for a phone', async ({ page }) => {
    await page.goto('/deals');
    await expect(page.getByText('Tap a deal to call the shop.')).toBeVisible();
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/deals.spec.js
Cannot use({ defaultBrowserType }) in a describe group, because it forces a new worker.
Make it top-level in the test file or put in the configuration file.

   at deals.spec.js:4

  2 |
  3 | test.describe('an iPhone', () => {
> 4 |   test.use(devices['iPhone 13']);
    |        ^
  5 |
  6 |   test('gets the page for a phone', async ({ page }) => {
  7 |     await page.goto('/deals');
```

O descritor traz `defaultBrowserType: 'webkit'`, e o motor do navegador é escolhido quando um worker
começa, não por bloco. A resposta do Playwright, *put it in the configuration file*, quer dizer um
**projeto**, que a aula 10 cobre junto com o resto da configuração. Aqui o arquivo mantém tudo o
mais que o descritor define e deixa o motor de fora, como o `viewport.mjs` também fez. Ele ainda
verifica o cabeçalho `Vary` e acrescenta a janela estreita de computador que tem de receber a
página de computador. Salve-o como `tests/deals.spec.js`:

```javascript
import { test, expect, devices } from '@playwright/test';

// The iPhone 13 descriptor asks for WebKit, and a browser type cannot
// change inside a describe block. Keep the rest of it, in Chromium.
const { defaultBrowserType, ...iPhone13 } = devices['iPhone 13'];

test.describe('an iPhone, emulated in Chromium', () => {
  test.use(iPhone13);

  test('gets the page for a phone', async ({ page }) => {
    const response = await page.goto('/deals');
    await expect(page.getByText('Tap a deal to call the shop.')).toBeVisible();
    expect(response.headers()['vary']).toBe('User-Agent');
  });
});

test.describe('a desktop browser in a phone-sized window', () => {
  test.use({ viewport: { width: 390, height: 664 } });

  test('gets the page for a desktop', async ({ page }) => {
    await page.goto('/deals');
    await expect(page.getByText('Weekly deals, in a table.')).toBeVisible();
  });
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/deals.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/deals.spec.js:10:3 › an iPhone, emulated in Chromium › gets the page for a phone (122ms)
  ✓  2 tests/deals.spec.js:20:3 › a desktop browser in a phone-sized window › gets the page for a desktop (86ms)

  2 passed (1.7s)
```

## Um palpite tem bordas

A regra do servidor é um palpite sobre aparelhos, e um palpite pode ser testado onde erra. A
própria lista do Playwright marca como `isMobile` alguns aparelhos cujo `User-Agent` não tem
`Mobile`:

```
ana@laptop:~/quitanda$ node -p "Object.entries(require('@playwright/test').devices).filter(([name, d]) => d.isMobile && !/Mobile/.test(d.userAgent)).map(([name]) => name)"
[
  'Blackberry PlayBook',
  'Blackberry PlayBook landscape',
  'Galaxy Tab S4',
  'Galaxy Tab S4 landscape',
  'Galaxy Tab S9',
  'Galaxy Tab S9 landscape',
  'Kindle Fire HDX',
  'Kindle Fire HDX landscape',
  'Nexus 10',
  'Nexus 10 landscape',
  'Nexus 7',
  'Nexus 7 landscape'
]
```

Doze entradas, seis tablets em duas posições cada, e todos recebem a página de computador. Pode ser
o que a loja quer, já que um tablet é quase um notebook, ou pode ser um defeito; o código não diz,
então alguém decide, e a decisão vira um teste. **Os descritores que valem um teste numa página
adaptativa são os dos dois lados da regra do servidor**, do mesmo jeito que as larguras que valem
um teste numa página responsiva são as dos dois lados dos breakpoints.

## O que a emulação não é

Tudo acima rodou num **Chromium usando o nome de um iPhone**. Ele tinha a janela, a razão de pixels,
o toque e o `User-Agent` do iPhone, e continuava sendo Chromium. Não é o Safari: o motor do iPhone
é o WebKit, que desenha, rola e falha de outro jeito, e o Playwright consegue rodar a própria versão
do WebKit para uma resposta bem mais próxima. **O WebKit não foi rodado neste curso**: a máquina de
onde vêm estas transcrições não alcança o download dele pelo Playwright, então nada aqui afirma o
que o WebKit faz.

E nenhuma emulação é um celular na mão de alguém: não tem o processador dele, a memória, a rede num
ônibus, o teclado na tela cobrindo metade do formulário, nem a barra de endereço do navegador que
aparece e some conforme a página rola. A emulação responde *o que esta página faz neste tamanho, com
este nome*; um aparelho de verdade responde o resto, que é o tema de `api-mobile-automation` e,
para olhar à mão, da aula 7 de `manual-testing`.
