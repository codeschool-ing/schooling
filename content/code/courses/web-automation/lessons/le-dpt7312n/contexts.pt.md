---
title: Contextos, e dois clientes num navegador
version: 1
---

Iniciar um navegador custa tempo: um processo, a memória dele, um segundo ou mais até ele
responder. O jeito óbvio de manter os testes separados seria um navegador novo para cada um, e o
jeito óbvio de poupar esse tempo seria dividir um só e deixar os testes arrumarem a bagunça uns
dos outros. **O Playwright não faz nenhum dos dois.** Ele inicia um navegador por worker e dá a
cada teste um **contexto de navegador**, que é um perfil novo dentro desse navegador: os próprios
cookies, o próprio `localStorage`, o próprio cache, como se outra pessoa tivesse aberto uma janela
anônima.

O aninhamento tem três níveis. Um **navegador** contém contextos; um **contexto** contém páginas;
uma **página** é uma aba. Páginas do mesmo contexto dividem tudo o que um perfil guarda, como duas
abas do seu próprio navegador. Páginas de contextos diferentes não dividem nada, e criar um contexto
leva milissegundos, e é por isso que dá para ter um por teste.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um navegador contém dois contextos. O da Ana tem duas páginas e o da Bia tem uma; cada contexto tem seus próprios cookies, storage e cache. Os dois mandam requisições à mesma loja, que guarda uma cesta para todo mundo.\"><rect x=\"20\" y=\"20\" width=\"440\" height=\"250\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\"></rect><text x=\"36\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" fill=\"var(--paper-dim)\">um navegador, aberto uma vez</text><rect x=\"40\" y=\"60\" width=\"190\" height=\"190\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">contexto da Ana</text><rect x=\"55\" y=\"96\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma página</text><rect x=\"55\" y=\"136\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"135\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma segunda página</text><text x=\"135\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">seus próprios</text><text x=\"135\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cookies, storage,</text><text x=\"135\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cache</text><rect x=\"250\" y=\"60\" width=\"190\" height=\"190\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect><text x=\"345\" y=\"82\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">contexto da Bia</text><rect x=\"265\" y=\"96\" width=\"160\" height=\"30\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect><text x=\"345\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma página</text><text x=\"345\" y=\"196\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">seus próprios</text><text x=\"345\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cookies, storage,</text><text x=\"345\" y=\"228\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cache</text><rect x=\"540\" y=\"90\" width=\"160\" height=\"120\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\"></rect><text x=\"620\" y=\"116\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a loja</text><text x=\"620\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">/api/basket</text><text x=\"620\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">uma cesta</text><text x=\"620\" y=\"186\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">para todo mundo</text><path d=\"M430 120 L536 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M536 120 L527 115 L527 125 Z\" fill=\"var(--phosphor)\"></path><path d=\"M430 170 L536 170\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><path d=\"M536 170 L527 165 L527 175 Z\" fill=\"var(--phosphor)\"></path><text x=\"498\" y=\"108\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Ana põe</text><text x=\"498\" y=\"158\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Bia lê</text></svg>", "caption": "Um contexto separa tudo o que o navegador guarda. A cesta da loja fica no servidor, e nenhum contexto chega até ela.", "same": ["cache", "cookies, storage,"]}
```

## Dois clientes num teste

O `page` que cada teste recebeu até aqui foi feito a partir de um contexto que o Playwright criou
para aquele teste. Um teste também pode pedir o próprio `browser` e criar quantos contextos
precisar, e é assim que um teste faz o papel de duas pessoas. Este arquivo tem quatro testes: dois
contextos que não dividem nada, dois clientes na loja, e um par mostrando que o `page` comum também
é isolado. Salve-o como `tests/contexts.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// Every test starts from an empty basket.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('two contexts share nothing in the browser', async ({ browser }) => {
  const ana = await browser.newContext();
  const bia = await browser.newContext();
  const anaPage = await ana.newPage();
  const biaPage = await bia.newPage();
  await anaPage.goto('/');
  await biaPage.goto('/');

  const shopper = () => localStorage.getItem('shopper');
  await anaPage.evaluate(() => localStorage.setItem('shopper', 'ana'));
  console.log(`Ana's page reads ${await anaPage.evaluate(shopper)}`);
  console.log(`Bia's page reads ${await biaPage.evaluate(shopper)}`);
  expect(await biaPage.evaluate(shopper)).toBeNull();

  // A second page in Ana's context is her second tab: same storage.
  const anaTab = await ana.newPage();
  await anaTab.goto('/');
  expect(await anaTab.evaluate(shopper)).toBe('ana');

  await ana.close();
  await bia.close();
});

test('two shoppers, one basket: the shop\'s flaw', async ({ browser }) => {
  const ana = await browser.newContext();
  const bia = await browser.newContext();
  const anaPage = await ana.newPage();
  const biaPage = await bia.newPage();
  const add = (page, id) =>
    page.getByTestId(`product-${id}`).getByRole('button', { name: 'Add to basket' }).click();

  await anaPage.goto('/');
  await add(anaPage, 'banana');
  await expect(anaPage.getByTestId('basket-count')).toHaveText('1');

  await biaPage.goto('/');
  console.log(`cookies: Ana ${JSON.stringify(await ana.cookies())}, Bia ${JSON.stringify(await bia.cookies())}`);
  // Bia has added nothing, and her basket already holds Ana's banana.
  await expect(biaPage.getByTestId('basket-count')).toHaveText('1');

  await add(biaPage, 'mango');
  await anaPage.reload();
  await expect(anaPage.getByTestId('basket-count')).toHaveText('2');
  console.log(`Ana's total after Bia's mango: ${await anaPage.locator('.basket-total').textContent()}`);

  await ana.close();
  await bia.close();
});

test('the page fixture: storage written in one test', async ({ page }) => {
  await page.goto('/');
  await page.evaluate(() => localStorage.setItem('shopper', 'ana'));
  expect(await page.evaluate(() => localStorage.getItem('shopper'))).toBe('ana');
});

test('the next test in the same browser starts without it', async ({ page }) => {
  await page.goto('/');
  expect(await page.evaluate(() => localStorage.getItem('shopper'))).toBeNull();
});
```

O `request` do `beforeEach` é uma fixture que manda requisições HTTP sem página nenhuma, e ela
esvazia a cesta com `POST /api/reset` antes de cada teste. Contextos criados com
`browser.newContext()` pegam o `baseURL` e as outras opções de `use` da configuração, então
`goto('/')` funciona neles como funciona em `page`.

```
%%CAP contexts%%
```

## O que a execução diz

O primeiro teste é o isolamento prometido. A página da Ana gravou `shopper` no `localStorage` e lê
de volta; a página da Bia, a mesma loja no mesmo navegador, lê `null`. Uma segunda página no
contexto da Ana lê `ana`, porque é a segunda aba dela.

O segundo teste é **a falha da loja, mostrada pela ferramenta que não esconde nada**. O contexto da
Bia é novo. Ele não tem cookies, e a linha impressa no meio mostra que nenhuma das duas tem: a loja
nunca define um, então não tem com que distinguir duas pessoas. A Bia abre a loja sem ter posto
nada, e a cesta dela diz `1`, porque a banana é da Ana e **a cesta mora no servidor, como uma lista
só para todo mundo**. A Bia põe uma manga, a Ana recarrega, e o total da Ana agora é @@TOTAL@@. Um
contexto isola o que o navegador guarda. Não consegue isolar o que o servidor guarda, e nenhuma
configuração do Playwright consegue.

Leia o teste pelo que ele é: uma descrição da loja como ela se comporta hoje. Se uma versão futura
desse a cada visitante a sua própria cesta, a expectativa de `1` na página da Bia falharia, e essa
falha seria uma boa notícia. A aula 15 trata de dados de teste e de isolamento do lado do servidor,
e começa por essa falha.

Os dois últimos testes usam o `page` comum. O primeiro grava `shopper` e lê de volta; o seguinte
roda **no mesmo worker e no mesmo navegador**, um instante depois, e não acha nada, porque o `page`
dele pertence a um contexto feito só para ele. Esse é o padrão, e é por isso que a ordem dos testes
num arquivo não importa para o que o navegador lembra.

## Onde o isolamento acaba

Cada worker tem o seu navegador, e cada teste o seu contexto, então nada do navegador vaza entre
testes. **Tudo o que fica fora do navegador ainda vaza.** A cesta, um banco de dados, um arquivo que
o servidor grava, um e-mail que ele manda: dois testes rodando ao mesmo tempo em dois workers
dividem tudo isso, como os dois contextos acima dividiram a cesta. Dentro de um arquivo, os testes
rodam um depois do outro por padrão, e é por isso que os resets deste arquivo não tropeçam uns nos
outros. Rode a suíte inteira com vários workers e a cesta única da loja vira uma cesta para todos os
testes ao mesmo tempo; a aula 19 trata de execução em paralelo e encara isso de frente.

Um contexto por teste também é o motivo de um teste que precisa de um usuário logado ter de fazer
login de novo, ou carregar um estado salvo: os cookies do teste anterior foram embora com o
contexto dele. O `storageState` do Playwright salva os cookies e o storage de um contexto num
arquivo e inicia um contexto novo a partir dele. A loja não tem login, então isso não é mostrado
aqui.
