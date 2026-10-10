---
title: A página carregou, e os dados não
version: 1
---

**Uma página que carregou não é uma página que terminou.** O navegador diz que a página carregou
quando o documento e os arquivos que ele nomeia, as folhas de estilo, os scripts e as imagens,
chegaram. Uma requisição que um script faz depois disso não entra na conta, e em muitíssimas
páginas o conteúdo que interessa a um teste vem exatamente de uma requisição assim. O nome disso,
*Ajax*, é mais antigo que a função `fetch` que faz a requisição hoje. Quer dizer só isto: a página
pede dados ao servidor de forma **assíncrona**, sem sair da página e sem o navegador esperar a
resposta para dar a página como pronta.

A página inicial da loja, da aula 1, é o primeiro exemplo. O HTML chega com uma lista vazia; o
`app.js` roda, chama `fetch('/api/products')` e preenche a lista quando a resposta vem. A aula 1
mostrou a ordem no painel Network: o documento, depois o script, depois a requisição dos produtos,
por último. Entre o documento e essa resposta, a página está na tela e vazia.

## Onde um teste olha

A primeira ideia comum é que `page.goto()` espera *a página*, de modo que, quando ele retorna, tudo
está lá. Ele espera o **evento `load`** do navegador, por padrão, e nada mais. Se os produtos estão
na lista nesse momento depende de quem terminou primeiro: o evento `load` ou a requisição dos
produtos. Nada na página decide isso. Quem decide é o tempo.

Este programa torna a corrida visível. Ele imprime quando o evento `load` dispara, quando cada
requisição a `/api/` é respondida, quantos produtos a lista tem no momento em que o `goto` retorna,
e quantos depois que um produto apareceu. Uma chamada, `page.route`, permite segurar a resposta dos
produtos pelo número de milissegundos que você der, o que faz o papel de um servidor ou de uma rede
mais lentos. Salve como `at-load.mjs`:

```javascript
// When the home page counts as loaded, and when its products arrive.
// Run it with the shop started: node at-load.mjs [ms to hold the products back]
import { chromium } from '@playwright/test';

const hold = Number(process.argv[2] ?? 0);
const browser = await chromium.launch();
const page = await browser.newPage();
const start = Date.now();
const log = (text) => console.log(String(Date.now() - start).padStart(5) + ' ms  ' + text);

// Holding the answer back stands in for a slower server or network.
await page.route('**/api/products', async (route) => {
  await new Promise((resolve) => setTimeout(resolve, hold));
  await route.continue();
});
page.on('load', () => log('the load event'));
page.on('response', (response) => {
  const path = new URL(response.url()).pathname;
  if (path.startsWith('/api/')) log(`answered ${path}`);
});

const products = page.locator('#products li');
await page.goto('http://localhost:3000/');
log(`goto returned: ${await products.count()} products`);
await products.first().waitFor();
log(`one appeared: ${await products.count()} products`);
await browser.close();
```

Com a loja iniciada, rode do jeito que está, e depois segurando os produtos por meio segundo:

```
ana@laptop:~/quitanda$ node at-load.mjs
   57 ms  the load event
   67 ms  answered /api/products
   85 ms  answered /api/basket
   89 ms  goto returned: 8 products
   97 ms  one appeared: 8 products
ana@laptop:~/quitanda$ node at-load.mjs 500
   51 ms  the load event
   79 ms  goto returned: 0 products
  555 ms  answered /api/products
  562 ms  answered /api/basket
  888 ms  one appeared: 8 products
```

Nesta máquina a loja responde em poucos milissegundos, então na primeira execução os produtos
chegaram mais ou menos junto com o evento `load`, e a lista estava cheia quando o `goto` retornou.
**Isso é sorte, de um tipo confiável.** Na segunda execução nada mudou na página, só a velocidade de
uma resposta, e o `goto` retornou com uma lista de **0** produtos. Um teste que os contasse nesse
momento teria falhado numa página sem nada de errado.

## As duas saídas

Há duas maneiras de impedir que a velocidade do servidor decida um teste.

A primeira é **esperar um tempo**: meio segundo, dois segundos, o que tiver feito o teste passar
no dia em que foi escrito. Isso troca *quase sempre rápido o bastante* por *quase sempre devagar o
bastante*, e falha na primeira vez que a resposta demorar mais que o palpite, num servidor de build
ocupado, por exemplo.

A segunda é **esperar o estado de que o teste precisa**. O `at-load.mjs` faz isso antes da última
linha: `products.first().waitFor()` retorna assim que existe um produto, leve isso quatro
milissegundos ou quatrocentos. O teste de fumaça da aula 1 faz a mesma coisa de forma mais curta.
`expect(page.locator('#products li')).toHaveCount(8)` não conta uma vez só; conta de novo e de novo
até a resposta ser 8 ou o tempo permitido acabar, então uma resposta lenta o deixa mais lento, e
não errado.

O resto desta aula trata de uma página em que esperar um estado não basta sozinho, porque a página
passa pelo estado certo a caminho de um errado.
