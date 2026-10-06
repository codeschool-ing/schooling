---
title: Sete primitivos, e objetos
version: 1
---

**Todo valor em JavaScript é um primitivo ou um objeto.** Um primitivo é um valor único e
imutável: um número, um texto, verdadeiro ou falso. Um objeto é uma coleção de valores que você
pode mudar, e arrays e funções também são objetos. Existem sete tipos primitivos, e `typeof` diz o
tipo de qualquer valor:

```javascript
const values = [42, 3.14, "Dom Casmurro", true, undefined, null, 10n, Symbol("id"), {}, [], () => {}];

for (const v of values) {
  console.log(typeof v);
}
console.log(Array.isArray([]), Array.isArray({}));
```

```
ana@dev:~/js$ node types.js
number
number
string
boolean
undefined
object
bigint
symbol
object
object
function
true false
```

Leia a lista junto com a saída:

| valor | `typeof` | o tipo |
|---|---|---|
| `42`, `3.14` | `number` | todo número, inteiro ou não, é um tipo só |
| `"Dom Casmurro"` | `string` | texto |
| `true` | `boolean` | `true` ou `false` |
| `undefined` | `undefined` | um nome ainda sem valor |
| `null` | `object` | **um "nada" proposital; a resposta é um erro** |
| `10n` | `bigint` | um número inteiro de qualquer tamanho |
| `Symbol("id")` | `symbol` | um valor com garantia de ser único |
| `{}`, `[]` | `object` | objetos |
| `() => {}` | `function` | uma função, que é um objeto que pode ser chamado |

## Duas respostas para lembrar

**`typeof null` é `"object"`, e isso é um bug de 1995 que nunca vai poder ser consertado**: páginas
demais na web dependem dele. `null` é um primitivo. Para testá-lo, compare direto: `value === null`.

**`typeof []` também é `"object"`**, porque um array é um objeto. `Array.isArray` é o teste que
separa os dois, e a última linha imprimiu `true false`.

## `undefined` e `null`

Os dois significam "sem valor", e a diferença é quem disse isso. **`undefined` é o que a linguagem
te dá**: um nome declarado sem nada atribuído, uma propriedade que falta, um parâmetro que ninguém
passou, o resultado de uma função sem `return`. **`null` é o que um programador escreve** para
dizer "vazio de propósito", como um livro ainda sem imagem de capa. A aula 4 encontra os dois em
propriedades que faltam, e a última seção desta aula mostra o operador que trata os dois igual.

## Primitivos não mudam

`"Dom Casmurro".toUpperCase()` devolve uma string nova e deixa a original em paz. **Nenhuma operação
muda um primitivo no lugar**; ela sempre produz outro. É por isso que `const` num número ou numa
string fixa de verdade o valor, enquanto `const` num array, na aula 1, só fixou o nome.
