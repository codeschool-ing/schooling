---
title: Escolhendo a camada em que uma verificação roda
version: 1
---

Os produtos de `/ssr` estão no HTML, e isso muda qual ferramenta é a mais barata para verificá-los.
Um teste de navegador inicia um navegador, carrega a página e tudo o que ela pede, roda os scripts
dela e espera. Uma requisição HTTP envia um pedido e lê uma resposta. **Quando o que você quer saber
já está no HTML, a requisição basta**, e uma verificação que dispensa navegador é mais rápida e tem
menos jeitos de falhar por motivos que nada têm a ver com a página.

## Um teste sem navegador

A fixture `request` do Playwright é um cliente HTTP que já conhece o `baseURL` da configuração. Um
teste que pede só `request`, e nunca `page`, não abre página nenhuma. O primeiro teste abaixo pede
os produtos à API da loja e verifica que cada um deles está no HTML de `/ssr`, de modo que um
produto acrescentado à loja e deixado fora da página o faz falhar. O segundo pergunta o mesmo a
`/`. Salve-o como `tests/ssr-html.spec.js`:

```javascript
import { test, expect } from '@playwright/test';

// No page and no browser: only the request fixture, which speaks HTTP.
test('the HTML of /ssr names every product the API lists', async ({ request }) => {
  const products = await (await request.get('/api/products')).json();
  const html = await (await request.get('/ssr')).text();
  for (const product of products) {
    expect(html).toContain(`<h2>${product.name}</h2>`);
  }
});

test('the HTML of / names none of them', async ({ request }) => {
  const html = await (await request.get('/')).text();
  expect(html).not.toContain('<h2>');
});
```

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr-html.spec.js

Running 2 tests using 1 worker

  ✓  1 tests/ssr-html.spec.js:4:1 › the HTML of /ssr names every product the API lists (50ms)
  ✓  2 tests/ssr-html.spec.js:12:1 › the HTML of / names none of them (15ms)

  2 passed (1.2s)
```

Os dois passam, em 50 ms e 15 ms, contra 121 ms e 103 ms dos dois testes da seção anterior, que
abriram uma página cada um e não rodaram nada nela. Numa página deste tamanho a diferença é de
poucas dezenas de milissegundos; o que uma requisição também poupa são todos os jeitos de um teste
de navegador falhar por conta própria.

O segundo teste mostra o limite desta camada. O HTML de `/` não tem nada para verificar, então a
pergunta "os produtos estão na página inicial" não tem resposta sem um navegador que rode o
`app.js`, que é o que o teste de fumaça da aula 1 faz.

## O que cada camada consegue ver

| o que você quer saber | uma requisição HTTP | um navegador |
|---|---|---|
| os produtos estão no que `/ssr` envia | sim | sim |
| os produtos estão em `/` | não, eles não estão no HTML | sim, depois que o `app.js` rodou |
| o Add to basket funciona | não | sim, quando a página está pronta |
| `/ssr` lista os produtos sem script | sim, o HTML é a resposta | sim, com `javaScriptEnabled: false` |

**A camada mais barata tem um ponto cego que importa nesta aula.** O HTML de `/ssr` esteve certo o
tempo todo, inclusive durante o segundo e meio em que os botões não faziam nada. Um teste HTTP passa
na página cujo teste falhou cinco vezes em cinco, porque o defeito está no que acontece depois que o
HTML chega. Então uma página renderizada no servidor pede as duas coisas: uma verificação rápida de
que o servidor escreve o conteúdo certo, e um teste de navegador para o momento em que a página fica
utilizável.

Os três arquivos desta aula, juntos:

```
ana@laptop:~/quitanda$ npx playwright test tests/ssr.spec.js tests/no-script.spec.js tests/ssr-html.spec.js

Running 5 tests using 2 workers

  ✓  2 tests/ssr-html.spec.js:4:1 › the HTML of /ssr names every product the API lists (63ms)
  ✓  3 tests/ssr-html.spec.js:12:1 › the HTML of / names none of them (32ms)
  ✓  1 tests/no-script.spec.js:6:1 › /ssr lists its eight products without a script (174ms)
  ✓  5 tests/no-script.spec.js:13:1 › / lists nothing without a script (105ms)
  ✓  4 tests/ssr.spec.js:8:1 › a click on /ssr adds to the basket once the page is ready (2.0s)

  5 passed (3.6s)
```

Cinco testes em dois workers. O que espera a página levou 2,0 s, e cada um dos outros quatro levou
entre 32 ms e 174 ms.

A regra por baixo desta seção é verificar cada coisa na camada mais barata que consegue vê-la, e
guardar o navegador para o que só um navegador vê. A aula 21 faz dela a pirâmide de testes, e a
aula 1 de `testing-cicd` dá nome às camadas. Testes que falam só HTTP são o assunto do próximo curso,
`api-mobile-automation`.
