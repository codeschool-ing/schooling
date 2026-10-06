---
title: Iteráveis, for of e for in
version: 1
---

**Arrays, strings, `Map`, `Set`, o objeto `arguments` e a `NodeList` de uma página são iteráveis.**
Objetos simples não são. E o `for…of` tem um primo mais velho, o `for…in`, que parece quase igual e
faz outra coisa:

```javascript
const shelf = ["Iracema", "Dom Casmurro"];
Array.prototype.extra = "added by some library";

for (const i in shelf) {
  console.log("in:", i, typeof i);
}
for (const title of shelf) {
  console.log("of:", title);
}

const loans = new Map([["Iracema", 3]]);
for (const [title, n] of loans) {
  console.log(title, n);
}
```

```
ana@dev:~/js$ node of-in.js
in: 0 string
in: 1 string
in: extra string
of: Iracema
of: Dom Casmurro
Iracema 3
```

**O `for…in` percorre nomes de propriedade**, e para um array esses são os índices, como strings:
`"0"`, `"1"`. Ele também inclui **propriedades enumeráveis herdadas pela cadeia de protótipos**
(aula 8), e foi assim que `extra`, acrescentada a `Array.prototype` do jeito que algumas bibliotecas
antigas faziam, apareceu como um terceiro "índice". O `for…of` perguntou ao iterador do array, que dá
os itens e nada mais.

**Use `for…of` para os itens de qualquer coisa iterável.** O `for…in` pertence aos objetos simples,
se a algum lugar, e mesmo lá `Object.keys` ou `Object.entries` (aula 4) são mais claros, porque
listam só as propriedades próprias do objeto.

## Objetos simples

```javascript
const book = { title: "Iracema", year: 1865 };
for (const [key, value] of Object.entries(book)) {
  console.log(key, value);
}
for (const part of book) {
  console.log(part);
}
```

```
ana@dev:~/js$ node not-iterable.js 2>&1 | head -n 7
title Iracema
year 1865
/home/ana/js/not-iterable.js:5
for (const part of book) {
                   ^

TypeError: book is not iterable
```

Um objeto simples não tem `Symbol.iterator`, então o `for…of` o recusou com **`book is not
iterable`**. Isso é proposital: um objeto poderia razoavelmente iterar sobre as chaves, os valores ou
as entradas, e a linguagem não escolhe por você. `Object.entries(book)` devolve um array de pares,
que é iterável, e desestruturar cada par deu o nome e o valor.

## Quem mais usa o protocolo

```javascript
const noisy = {
  [Symbol.iterator]() {
    let n = 0;
    return {
      next() {
        n += 1;
        console.log(`  next() call ${n}`);
        return n <= 2 ? { value: n * 10, done: false } : { value: undefined, done: true };
      },
    };
  },
};

console.log("spread:", [...noisy]);
console.log("destructuring:");
const [first] = noisy;
console.log(first);
console.log("Array.from:", Array.from(noisy));
```

```
ana@dev:~/js$ node consumers.js
  next() call 1
  next() call 2
  next() call 3
spread: [ 10, 20 ]
destructuring:
  next() call 1
10
  next() call 1
  next() call 2
  next() call 3
Array.from: [ 10, 20 ]
```

`noisy` é um iterável feito à mão que imprime a cada vez que lhe pedem um item. **O spread e o
`Array.from` pediram até o iterador dizer que terminou**, três chamadas para dois itens. **A
desestruturação de um nome pediu uma vez e parou**, porque já tinha o que precisava. `new Map(…)`,
`new Set(…)`, `Promise.all` (aula 14) e o `yield*` mais adiante nesta aula consomem iteráveis do
mesmo jeito.
