---
title: A cadeia de protótipos
version: 1
---

Um protótipo é um objeto, então também tem protótipo, e a busca continua. **A sequência de
protótipos de um objeto até o fim é a sua cadeia de protótipos**, e todo objeto que você usou neste
curso tem uma:

```javascript
const list = ["Iracema"];

let p = list;
const names = [];
while (p !== null) {
  p = Object.getPrototypeOf(p);
  names.push(p === Array.prototype ? "Array.prototype" : p === Object.prototype ? "Object.prototype" : String(p));
}
console.log(names.join("  ->  "));

console.log(Object.hasOwn(Array.prototype, "map"), Object.hasOwn(Object.prototype, "hasOwnProperty"));
console.log(list.map === Array.prototype.map);
console.log(list.missing);
```

```
ana@dev:~/js$ node chain.js
Array.prototype  ->  Object.prototype  ->  null
true true
true
undefined
```

A cadeia de um array é curta. O protótipo dele é `Array.prototype`, que guarda `map`, `filter`,
`push` e o resto; o protótipo desse objeto é `Object.prototype`, que guarda o que todo objeto sabe
fazer, como `hasOwnProperty` e `toString`; e **o protótipo de `Object.prototype` é `null`, onde toda
cadeia termina**. `list.map` não é uma cópia de `Array.prototype.map`; é a mesma função, achada
subindo um degrau, e o `===` confirma.

Quando a caminhada chega a `null` sem achar o nome, a resposta é `undefined`, como mostra
`list.missing`. **Uma propriedade que falta custa uma caminhada pela cadeia inteira**, e é por isso
que nunca é erro e nunca é instantânea.

Isso explica duas coisas de aulas anteriores. O objeto vazio da aula 5 que já tinha um `constructor`
o tinha herdado de `Object.prototype`. E o dicionário `Object.create(null)` da aula 7 não tinha
**cadeia nenhuma**, e é por isso que não tinha `hasOwnProperty` para chamar.

## O nome do vínculo

O vínculo em si se escreve `[[Prototype]]` na especificação, com colchetes duplos porque não é uma
propriedade que dê para ler pelo nome. `Object.getPrototypeOf(obj)` o lê e `Object.setPrototypeOf` o
muda, embora mudar o protótipo de um objeto que já existe seja lento em todo motor e raramente
necessário. Você também vai ver **`__proto__`** em código antigo e em saídas do console: um acessor
mais antigo para o mesmo vínculo, mantido por compatibilidade, e não o que se deve escrever.

Não confunda com **`prototype`**, a propriedade comum que as funções têm. A próxima seção trata
dela, e a diferença entre as duas é a fonte da maior parte da confusão sobre este assunto.
