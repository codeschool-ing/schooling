---
title: Funções são valores
version: 1
---

Em JavaScript **uma função é um valor**, com o mesmo estatuto de um número ou de uma string. Ela pode
receber um nome, ser passada para outra função, ser devolvida por uma e ser guardada num array ou
num objeto. Das linguagens em que isso vale se diz que têm **funções de primeira classe**, e todo o
resto desta aula decorre daí:

```javascript
function shout(text) {
  return text.toUpperCase() + "!";
}

const say = shout;
console.log(say("hello"));

function applyTwice(fn, value) {
  return fn(fn(value));
}
console.log(applyTwice(shout, "hi"));

function makeGreeting(greeting) {
  return (name) => `${greeting}, ${name}`;
}
const hello = makeGreeting("Hello");
const ola = makeGreeting("Olá");
console.log(hello("ana"), "/", ola("ana"));

console.log(typeof shout, shout.name, shout.length);
```

```
ana@dev:~/js$ node values.js
HELLO!
HI!!
Hello, ana / Olá, ana
function shout 1
```

## Quatro coisas que você faz com um valor-função

- **dar outro nome.** `const say = shout` copiou a referência, como a aula 4 mostrou para objetos,
  então `say` e `shout` são uma função só;
- **passar como argumento.** `applyTwice` recebeu `shout` e a chamou duas vezes. Uma função passada
  para ser chamada depois é um **callback**, e você já escreveu dezenas: toda função entregue a `map`
  ou `filter` na aula 4 era um;
- **devolver.** `makeGreeting` constrói uma arrow function nova a cada chamada e a devolve. Uma
  função que recebe ou devolve funções é uma **função de ordem superior**;
- **perguntar sobre ela.** `typeof` diz `"function"`, `name` é o nome com que foi declarada, e
  `length` é o número de parâmetros que ela declara.

## Por que isso importa

`hello` e `ola` vieram do mesmo `makeGreeting`, e cada uma lembrou uma saudação diferente. **O
parâmetro `greeting` pertencia a uma chamada de `makeGreeting` que já tinha terminado**, e mesmo
assim a arrow function conseguiu lê-lo. Isso não é truque das arrow functions; é como toda função
da linguagem funciona, e tem nome. As duas próximas seções chegam lá: primeiro como uma função acha
um nome, depois o que acontece quando a função sobrevive ao lugar onde foi feita.
