---
title: Esperando entre os itens
version: 2
---

Até aqui todo valor estava pronto no momento em que era pedido. Dados de uma rede não estão: a segunda
página de resultados chega algum tempo depois de você pedir. **Um gerador assíncrono é um gerador que
pode esperar entre os valores, e o `for await…of` é o laço que espera junto**:

```javascript
const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function* fetchPages(total) {
  for (let page = 1; page <= total; page += 1) {
    await wait(50);
    yield { page, titles: [`book ${page * 2 - 1}`, `book ${page * 2}`] };
  }
}

for await (const { page, titles } of fetchPages(3)) {
  console.log(page, titles);
}
console.log("all pages read");
```

```
ana@dev:~/js$ node async-pages.mjs
1 [ 'book 1', 'book 2' ]
2 [ 'book 3', 'book 4' ]
3 [ 'book 5', 'book 6' ]
all pages read
```

`fetchPages` finge ser uma API: espera 50 milissegundos antes de cada página, que uma de verdade
gastaria na rede. **O laço recebeu uma página, a imprimiu, e só então pediu a seguinte**, e
`all pages read` veio depois da terceira, porque o laço tinha esperado cada uma.

Três sintaxes novas estão neste arquivo, e as aulas 13 e 14 são o lugar delas:

- `async function*` cria um gerador assíncrono, e **o `await` dentro dele pausa até algo terminar**,
  aqui um temporizador;
- `new Promise(…)` é como `wait` transforma um temporizador em algo que o `await` consegue esperar;
- o `for await…of`, no nível de cima de um ES module (aula 9), pede cada item e espera ele chegar.

**O formato é o que levar desta aula**: a mesma conversa de puxar um por vez do `for…of`, com uma
pausa entre o pedido e a resposta. A aula 16 usa isso num servidor, onde a pausa é uma requisição de
verdade.
