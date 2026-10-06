---
title: Um depois do outro, ou todos de uma vez
version: 1
---

O `await` num laço espera cada passo antes de começar o seguinte. **Isso está certo quando cada passo
precisa do resultado do anterior, e é lento quando são independentes.** Quatro requisições de 300 ms
cada:

```javascript
const round = (ms) => Math.round(ms / 100) * 100;
const fetchBook = (id) => new Promise((resolve) => setTimeout(() => resolve({ id }), 300));
const ids = [7, 12, 19, 21];

let t = performance.now();
const one = [];
for (const id of ids) {
  one.push(await fetchBook(id));
}
console.log("one after another:", one.length, "books in about", round(performance.now() - t), "ms");

t = performance.now();
const all = await Promise.all(ids.map((id) => fetchBook(id)));
console.log("all at once:      ", all.length, "books in about", round(performance.now() - t), "ms");
```

```
ana@dev:~/js$ node timing.mjs
one after another: 4 books in about 1200 ms
all at once:       4 books in about 300 ms
```

O laço levou **uns 1200 ms**, quatro vezes 300: cada requisição só começou depois de a anterior
terminar. **O `Promise.all` levou uns 300 ms**: o `ids.map(…)` começou as quatro requisições de uma
vez, e o `Promise.all` esperou as quatro promessas juntas. A função `round` arredonda para os 100 ms
mais próximos no próprio programa, porque o número exato muda de uma execução para outra; o fator de
quatro não muda.

## Como saber de qual você precisa

Pergunte se um passo usa o que o passo anterior devolveu. **O autor do livro precisa do livro**, então
aqueles dois awaits estão em ordem de propósito. Quatro livros por id não precisam nada um do outro,
e esperar um por um é tempo que o usuário passa olhando um indicador de carregamento.

**Comece o trabalho primeiro, espere depois.** Chamar a função a começa, como fez o `map`; é o `await`
que espera. `const a = fetchBook(7); const b = fetchBook(12); await a; await b;` também roda as duas
juntas. O que não roda é `await fetchBook(7); await fetchBook(12);`, que parece quase igual.

Começar tudo de uma vez tem limite. Mil requisições num `Promise.all` podem sobrecarregar um servidor
ou bater no limite de conexões que um navegador abre para um mesmo host; para números grandes,
trabalhe em lotes.
