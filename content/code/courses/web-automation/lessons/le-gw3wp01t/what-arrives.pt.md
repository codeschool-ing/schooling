---
title: O que chega antes de qualquer script rodar
version: 1
---

A página inicial da loja chega vazia. A aula 1 mostrou isso: o HTML traz uma lista sem nada dentro,
e o `app.js` pede os produtos ao servidor depois que a página carregou e os desenha ele mesmo. Isso
é **renderização no cliente**: o servidor manda uma moldura e o navegador monta o conteúdo. Esta
aula acrescenta a mesma loja montada ao contrário. Com **renderização no servidor**, o servidor
escreve os produtos no HTML antes de enviá-lo, e o documento já chega dizendo o que está à venda.

A ideia comum é que as duas diferem só em velocidade, e que um teste escrito para uma passa na
outra. Elas quebram testes em lugares diferentes, e esta aula trata de onde.

## A página, renderizada no servidor

A rota nova responde a `/ssr` montando a lista inteira numa string e enviando-a, com os preços
formatados do jeito que o `app.js` os formata. O script embutido no fim da página espera o evento
`load` e então acrescenta um segundo script, `/slow/ssr.js`, que o servidor segura por um segundo e
meio; o comentário acima dessa pausa a marca como a falha desta aula. Salve-o como
`app/routes/ssr.js`:

```javascript
import fs from 'node:fs/promises';
import path from 'node:path';
import { send, pause } from '../http.js';
import { store } from '../store.js';

const money = new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' });
const script = path.join(import.meta.dirname, '..', 'public', 'ssr.js');

// The same shop, rendered on the server: the HTML arrives with the products
// already in it, and a script makes the buttons work once it has loaded.
function page() {
  const items = store.products.map((p) => `
      <li class="card" data-testid="product-${p.id}">
        <h2>${p.name}</h2>
        <p class="price">${money.format(p.price / 100)}</p>
        <button type="button" data-id="${p.id}">Add to basket</button>
      </li>`).join('');
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Quitanda, rendered on the server</title>
  <link rel="stylesheet" href="/style.css">
</head>
<body>
  <main>
    <h1>Fruit of the season</h1>
    <p>Basket: <span data-testid="basket-count">0</span> items</p>
    <ul id="products">${items}
    </ul>
  </main>
  <script>
    window.addEventListener('load', () => {
      const s = document.createElement('script');
      s.src = '/slow/ssr.js';
      document.body.append(s);
    });
  </script>
</body>
</html>`;
}

export const routes = [
  {
    method: 'GET', path: '/ssr',
    handle: ({ res }) => send(res, 200, page(), { 'Content-Type': 'text/html; charset=utf-8' }),
  },
  {
    method: 'GET', path: '/slow/ssr.js',
    handle: async ({ res }) => {
      // A known flaw, on purpose: the script that makes the buttons work
      // takes a second and a half to arrive.
      await pause(1500);
      send(res, 200, await fs.readFile(script, 'utf8'),
        { 'Content-Type': 'text/javascript; charset=utf-8' });
    },
  },
];
```

O servidor só lê `app/routes/` quando inicia, então pare-o com Ctrl+C e rode `npm start` de novo.
Depois abra `http://localhost:3000/ssr` ao lado de `http://localhost:3000/`. As duas mostram o
mesmo título e os mesmos oito cartões, cada um com seu botão. A página renderizada no servidor é
mais simples, com uma contagem de itens e sem cabeçalho, total ou aviso, porque foi escrita para
mostrar uma diferença e deixar o resto de fora.

## Perguntando sem navegador

O `curl` faz a primeira coisa que um navegador faz, pedir o documento, e nada depois disso: não roda
script nenhum. Conte os títulos de produto no que `/` envia:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ | grep -c '<h2>'
0
```

Nenhum. Faça a mesma pergunta a `/ssr` e imprima as linhas em vez de contá-las:

```
ana@laptop:~/quitanda$ curl -s http://localhost:3000/ssr | grep '<h2>'
        <h2>Banana</h2>
        <h2>Mango</h2>
        <h2>Papaya</h2>
        <h2>Guava</h2>
        <h2>Cashew fruit</h2>
        <h2>Passion fruit</h2>
        <h2>Acerola</h2>
        <h2>Pineapple</h2>
```

Os oito, na ordem em que a loja os lista, dentro do próprio documento.

## O que isso significa para um teste

**O jeito como uma página é renderizada decide que ferramentas conseguem ver o conteúdo dela.**
Tudo o que fala HTTP e não roda JavaScript vê oito produtos em `/ssr` e nenhum em `/`: o `curl`, um
script que busca uma página e a fixture `request` que o Playwright dá a um teste, que a última
seção de leitura desta aula usa. Em `/`, os produtos só existem depois que um navegador buscou o
`app.js`, rodou-o e teve a requisição dele a `/api/products` respondida. É por isso que todo teste
da página inicial neste curso abre um navegador, e por isso a aula 3 trata do momento em que um
teste olha cedo demais.

A página renderizada no servidor muda esse problema de lugar em vez de eliminá-lo. Os produtos
estão lá desde o primeiro byte, então um teste que só os lê não tem o que esperar. Um teste que os
**usa**, clicando num botão, ainda depende de um script, e a próxima seção mostra quanto isso custa.

## E para quem está num celular lento

O que uma pessoa vê enquanto espera é a outra metade. Com renderização no cliente, a moldura da
página aparece e a lista fica vazia até o script chegar, rodar, pedir e desenhar, e num celular
lento cada um desses passos demora mais. Com renderização no servidor, os produtos aparecem na tela
assim que o HTML aparece, e é esse o principal motivo de sites que se importam com os primeiros
segundos renderizarem no servidor.

O preço é que a página **parece** pronta antes de **estar** pronta. Uma pessoa vê um botão, toca
nele e nada acontece, porque o script que o faz funcionar ainda não chegou. Nesta loja esse atraso
é a pausa proposital do servidor e não um aparelho lento, o que o torna igual toda vez e fácil de
estudar. Medir quanto tempo uma página real leva para ficar utilizável é assunto da aula 10 de
`non-functional-testing`.
