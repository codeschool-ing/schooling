---
title: O cache que só cresce
version: 1
---

Um cache guarda respostas para não precisarem ser calculadas de novo (o `memoize` da aula 6 era um).
**Um cache sem limite é um vazamento com uma boa desculpa**: toda chave nova acrescenta uma entrada, e
nada nunca remove uma. Um servidor que renderiza um fragmento por livro, com livros novos a cada hora:

```javascript
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

const cache = new Map();
function render(bookId) {
  if (!cache.has(bookId)) cache.set(bookId, `<li>book ${bookId}</li>`.repeat(20));
  return cache.get(bookId);
}

for (let hour = 1; hour <= 4; hour++) {
  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);
  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);
}
```

```
ana@dev:~/js$ node --expose-gc cache-leak.js
hour 1: 50000 entries, 17 MB
hour 2: 100000 entries, 31 MB
hour 3: 150000 entries, 46 MB
hour 4: 200000 entries, 58 MB
```

**Cinquenta mil entradas por hora, de 12 a 15 MB por hora, e sem fim.** Nenhuma linha está errada, e o
coletor está certo em manter tudo: o `Map` é alcançável a partir do módulo, e o `Map` segura toda
entrada. Um servidor assim não cai no primeiro dia; ele fica mais lento conforme o coletor trabalha
mais, e cai alguns dias depois, numa hora que ninguém escolheu.

## Um cache com limite

```schooling-example
{
  "language": "javascript",
  "file": "cache-bounded.js",
  "parts": [
    {
      "code": "const mb = () => {\n  globalThis.gc();\n  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);\n};",
      "note": "A mesma medição."
    },
    {
      "code": "const LIMIT = 1000;\nconst cache = new Map();",
      "note": "O limite é a decisão que a primeira versão nunca tomou: no máximo 1000 entradas."
    },
    {
      "code": "function render(bookId) {\n  if (cache.has(bookId)) {\n    const value = cache.get(bookId);\n    cache.delete(bookId);\n    cache.set(bookId, value);\n    return value;\n  }",
      "note": "Um acerto move a entrada para o fim, apagando e definindo de novo. Um `Map` guarda as chaves na ordem em que foram definidas (aula 5), então o fim do `Map` é sempre a entrada usada mais recentemente."
    },
    {
      "code": "  const value = `<li>book ${bookId}</li>`.repeat(20);\n  cache.set(bookId, value);\n  if (cache.size > LIMIT) cache.delete(cache.keys().next().value);\n  return value;\n}",
      "note": "Uma falta calcula o valor e o guarda. Se isso passar o cache do limite, a primeira chave do `Map`, a usada há mais tempo, é removida."
    },
    {
      "code": "for (let hour = 1; hour <= 4; hour++) {\n  for (let i = 0; i < 50_000; i++) render(`${hour}-${i}`);\n  console.log(`hour ${hour}: ${cache.size} entries, ${mb()} MB`);\n}",
      "note": "As mesmas quatro horas de tráfego."
    }
  ],
  "output": "hour 1: 1000 entries, 4 MB\nhour 2: 1000 entries, 4 MB\nhour 3: 1000 entries, 4 MB\nhour 4: 1000 entries, 4 MB"
}
```

**O cache ficou em 1000 entradas e 4 MB durante quatro horas.** Esse tipo de cache se chama **LRU**,
least recently used, o menos usado recentemente: quando está cheio, esquece o que ninguém pede há mais
tempo. O limite é um julgamento sobre quanta memória as respostas valem, e qualquer limite é melhor
que nenhum.

Duas outras respostas servem a outros casos: **um `WeakMap`** (aula 5) quando as chaves são objetos
cuja vida deve decidir a da entrada, e **um prazo de validade** quando uma resposta envelhece, como
preços.
