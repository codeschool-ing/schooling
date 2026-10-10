---
title: Desenhado não é o mesmo que funcionando
version: 1
---

O HTML de `/ssr` desenha oito cartões, cada um com um botão **Add to basket**. São elementos
`<button>` de verdade, visíveis e habilitados, e **não fazem nada** até que um script dê a cada um
uma função para o clique. Os frameworks que renderizam no servidor chamam esse passo de
**hidratação**: o HTML chega seco, e um script que vem depois dele o faz responder. A loja faz isso à
mão, no arquivo que o servidor envia em `/slow/ssr.js`. Salve-o como `app/public/ssr.js`:

```javascript
// Until this file has run, the buttons on /ssr are drawn and do nothing.
for (const button of document.querySelectorAll('button[data-id]')) {
  button.addEventListener('click', async () => {
    const response = await fetch('/api/basket', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: button.dataset.id }),
    });
    const basket = await response.json();
    const count = basket.lines.reduce((n, line) => n + line.qty, 0);
    document.querySelector('[data-testid=basket-count]').textContent = count;
  });
}
document.body.dataset.ready = 'true';
```

A última linha dele põe `data-ready="true"` no `<body>`, depois que todo botão tem sua função. A
próxima seção tem um uso para isso.

## A lacuna, medida

O `look.mjs` da aula 1 imprime cada resposta que uma página recebe, com os milissegundos desde que
ele pediu a página. Primeiro a página inicial:

```
%%CAP look-csr%%
```

Depois `/ssr`, com o endereço como argumento:

```
%%CAP look-ssr%%
```

Em `/`, os produtos chegam aos TIME_PRODUCTS ms numa requisição própria, e até lá a lista fica vazia.
Em `/ssr` eles vieram com o documento, aos TIME_DOC ms, e o script que faz os botões funcionarem chegou
aos TIME_SCRIPT ms. **Durante cerca de um segundo e meio a página mostra oito botões que ignoram
todo clique.**

FIGURE

## Um teste que clica na hora

O teste óbvio abre a página, clica no botão da banana e verifica que a cesta diz 1. O `beforeEach`
esvazia a cesta antes, pela reinicialização da loja, porque a cesta é uma lista só, compartilhada
por todo mundo, e um teste anterior pode tê-la enchido; a aula 15 trata disso. Salve-o como
`tests/ssr.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// The basket is shared, so every test starts by emptying it.
test.beforeEach(async ({ request }) => {
  await request.post('/api/reset');
});

test('a click on /ssr adds to the basket', async ({ page }) => {
  await page.goto('/ssr');
  await page.getByTestId('product-banana').getByRole('button', { name: 'Add to basket' }).click();
  await expect(page.getByTestId('basket-count')).toHaveText('1');
});
```

```
%%CAP click-at-once%%
```

**O clique deu certo e a cesta ficou em 0.** O Playwright não reclamou do clique em si. Antes de
clicar, ele verifica que o elemento está visível, parado, habilitado e não coberto por outra coisa,
o que a documentação dele chama de **verificações de acionabilidade**, e o botão passou em todas.
Depois ele esperou os cinco segundos que uma asserção espera por padrão para o texto virar `1`, e
desistiu. Nenhuma verificação no botão poderia ter pegado isso, porque um botão sem função e um
botão com função parecem idênticos vistos de fora.

## Várias execuções, caso varie

Um problema de tempo costuma passar de vez em quando, então, antes de decidir o que fazer, descubra
de que tipo é o seu. O `--repeat-each` roda o teste esse número de vezes, o `--workers 1` roda as
cópias uma depois da outra, e o `grep` guarda as linhas que dizem como cada execução terminou. Por
padrão as cópias rodam em paralelo, e em paralelo elas dividiriam a cesta única da loja, de modo que
o clique de uma cópia poderia aparecer na contagem de outra; esse é o assunto da aula 15, e aqui só
turvaria a resposta:

```
%%CAP click-repeat%%
```

Cinco falhas em cinco. O `page.goto` retorna quando o evento `load` da página disparou, e só então o
script embutido pede `/slow/ssr.js`; o clique cai dentro do 1,5 s em que o servidor o segura, toda
vez. Encurte essa pausa para alguns milissegundos e o mesmo teste passaria numa máquina rápida e
falharia numa máquina carregada, que é a forma dos testes intermitentes da aula 14.
