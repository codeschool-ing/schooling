---
title: Alocar, usar, liberar
version: 2
---

Todo valor que o seu programa cria ocupa memória. **Alocá-lo é automático, usá-lo é o seu código, e
liberá-lo é trabalho do coletor de lixo.** O Node consegue mostrar os três, com uma opção feita
para experimentos, `--expose-gc`, que deixa um script rodar o coletor sob demanda, para cada número
ser tirado depois de uma coleta:

```javascript
const mb = () => {
  globalThis.gc();
  return Math.round(process.memoryUsage().heapUsed / 1024 / 1024);
};

console.log("at start:          ", mb(), "MB");

let books = Array.from({ length: 1_000_000 }, (_, i) => ({ id: i, title: `book ${i}` }));
console.log("a million books:   ", mb(), "MB");

books = null;
console.log("after letting go:  ", mb(), "MB");
```

```
ana@dev:~/js$ node --expose-gc lifecycle.js
at start:           3 MB
a million books:    80 MB
after letting go:   4 MB
```

**Um milhão de objetos pequenos ocupou uns 77 MB do heap**, a parte da memória onde moram os objetos
JavaScript. Pôr `books` em `null` largou a única referência ao array, e a coleta seguinte recuperou
quase tudo. O programa arredonda para megabytes inteiros, porque os números exatos mudam algumas
centenas de kilobytes de uma execução para outra.

Nada chamou `free`. **O único trabalho do programa foi parar de se referir aos dados**; o coletor
percebeu e fez o resto.

## Onde a memória aparece

```javascript
const mb = (n) => `${Math.round(n / 1024 / 1024)} MB`;
const u = process.memoryUsage();
console.log("rss      ", mb(u.rss), "  everything the process holds");
console.log("heapTotal", mb(u.heapTotal), "  the heap V8 has reserved");
console.log("heapUsed ", mb(u.heapUsed), "  what live JavaScript objects use");
console.log("external ", mb(u.external), "  memory outside the heap, such as buffers");
```

```
ana@dev:~/js$ node --expose-gc usage.js
rss       40 MB   everything the process holds
heapTotal 5 MB   the heap V8 has reserved
heapUsed  4 MB   what live JavaScript objects use
external  1 MB   memory outside the heap, such as buffers
```

- **`heapUsed`** é o número a observar para vazamentos no seu próprio código: a memória ocupada por
  objetos JavaScript vivos;
- `heapTotal` é o que o V8 reservou para o heap, que ele aumenta e diminui como achar melhor;
- `rss`, resident set size, é tudo o que o processo segura, inclusive o próprio Node e o código dele;
- `external` é memória guardada fora do heap em nome do JavaScript, como os bytes de um arquivo lido
  num buffer.

No navegador, o **painel Memory** das ferramentas de desenvolvedor faz o papel desses números, e a
aula 22 abre as ferramentas de desenvolvedor.
