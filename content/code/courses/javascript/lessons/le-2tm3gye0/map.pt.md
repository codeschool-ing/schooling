---
title: Map: um dicionário com chaves de qualquer tipo
version: 1
---

Antes de 2015 só havia um jeito de guardar valores por chave, que era usar os nomes das
propriedades de um objeto como chaves. **Funciona para strings que você controla, e falha de dois
jeitos silenciosos** para qualquer outra coisa:

```javascript
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = {};
loans[iracema] = 3;
loans[casmurro] = 5;
console.log(Object.keys(loans), loans[iracema]);

const counts = {};
for (const word of ["the", "constructor", "the"]) {
  counts[word] = (counts[word] || 0) + 1;
}
console.log(counts.the);
console.log(counts.constructor);
```

```
ana@dev:~/js$ node object-dictionary.js
[ '[object Object]' ] 5
2
function Object() { [native code] }1
```

**Nomes de propriedade são strings**, então os dois livros viraram a chave `"[object Object]"`, o
texto que a aula 2 mostrou para um objeto transformado em string. O segundo livro sobrescreveu o
primeiro, e `loans[iracema]` deu 5. A segunda falha é pior: **um objeto já tem propriedades
herdadas**, uma delas chamada `constructor`, então contar a palavra "constructor" começou de uma
função em vez de zero. A aula 8 explica de onde vêm as propriedades herdadas.

## `Map`

Um `Map` guarda chaves de qualquer tipo, comparadas como o `===` as compara, e não tem nada herdado
com que colidir:

```javascript
const iracema = { title: "Iracema" };
const casmurro = { title: "Dom Casmurro" };

const loans = new Map();
loans.set(iracema, 3);
loans.set(casmurro, 5);
loans.set(1, "the number one");
loans.set("1", "the string one");

console.log(loans.get(iracema), loans.get(casmurro));
console.log(loans.get(1), "/", loans.get("1"));
console.log(loans.size, loans.has(casmurro));
loans.delete(1);

for (const [key, value] of loans) {
  console.log(typeof key, value);
}
```

```
ana@dev:~/js$ node map.js
3 5
the number one / the string one
4 true
object 3
object 5
string the string one
```

- `set(chave, valor)` e `get(chave)` são os dois que você mais usa; `has`, `delete` e `size`
  completam;
- **os dois objetos são duas chaves**, porque são dois objetos. `1` e `"1"` também são, e um
  objeto os teria fundido numa propriedade só;
- um `Map` lembra **a ordem em que as chaves foram acrescentadas**, e `for…of` dá cada entrada como
  um par `[chave, valor]`, pronto para desestruturar.

## Ida e volta

```javascript
const prices = new Map([
  ["Iracema", 2990],
  ["Dom Casmurro", 3450],
]);
console.log(prices);

const asObject = Object.fromEntries(prices);
console.log(asObject);

const back = new Map(Object.entries(asObject));
console.log(back.get("Iracema"));
console.log(JSON.stringify(prices), JSON.stringify(asObject));
```

```
ana@dev:~/js$ node map-convert.js
Map(2) { 'Iracema' => 2990, 'Dom Casmurro' => 3450 }
{ Iracema: 2990, 'Dom Casmurro': 3450 }
2990
{} {"Iracema":2990,"Dom Casmurro":3450}
```

Um `Map` se constrói a partir de uma lista de pares, e `Object.fromEntries` e `Object.entries`
convertem nos dois sentidos quando as chaves são strings. **O `JSON.stringify` não conhece o `Map`**
e escreveu `{}`, jogando fora os dois preços em silêncio. A aula 16 trata de JSON; por ora,
converta um `Map` em objeto antes de mandá-lo para qualquer lugar como JSON.

A contagem de palavras, feita com um `Map`, não tem a armadilha herdada:

```javascript
const counts = new Map();
for (const word of ["the", "constructor", "the"]) {
  counts.set(word, (counts.get(word) ?? 0) + 1);
}
console.log(counts);
```

```
ana@dev:~/js$ node counts.js
Map(2) { 'the' => 2, 'constructor' => 1 }
```
