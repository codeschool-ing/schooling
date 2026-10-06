---
title: O que o for of pede
version: 1
---

O `for…of`, o spread e a desestruturação funcionam em mais coisas que arrays, e todos funcionam do
mesmo jeito por baixo. **Eles pedem ao valor um iterador, e depois pedem ao iterador um item por
vez.** As regras dessa conversa se chamam **protocolo de iteração**, e são pequenas o bastante para
rodar à mão:

```javascript
const shelf = ["Iracema", "Dom Casmurro"];
const it = shelf[Symbol.iterator]();

console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(it.next());
console.log(typeof Symbol.iterator, typeof shelf[Symbol.iterator]);
```

```
ana@dev:~/js$ node protocol.js
{ value: 'Iracema', done: false }
{ value: 'Dom Casmurro', done: false }
{ value: undefined, done: true }
{ value: undefined, done: true }
symbol function
```

## As duas metades

- **Um iterável** é um objeto com um método guardado na chave `Symbol.iterator`. Chamar esse método
  devolve um iterador. Arrays têm um, e é por isso que `shelf[Symbol.iterator]` é uma função;
- **um iterador** é um objeto com um método `next()`. Cada chamada devolve `{ value, done }`: o
  próximo item e `done: false`, ou, quando não sobra nada, `done: true`. Depois de terminado,
  continua terminado, como mostra a quarta chamada.

`Symbol.iterator` é um **símbolo**, o tipo primitivo que a aula 2 listou e nunca usou. Um símbolo é
uma chave que não colide com nenhuma string, então a linguagem pôde acrescentar esse método a todo
objeto embutido sem quebrar código que já tinha uma propriedade chamada `"iterator"`.

## Sobre o que uma string itera

```javascript
const word = "Olá \u{1F44B}";
console.log(word.length, [...word].length);
console.log([...word].map((ch) => ch.codePointAt(0).toString(16)));
console.log(word.split("").map((unit) => unit.charCodeAt(0).toString(16)));
```

```
ana@dev:~/js$ node strings.js
6 5
[ '4f', '6c', 'e1', '20', '1f44b' ]
[ '4f', '6c', 'e1', '20', 'd83d', 'dc4b' ]
```

`word` tem cinco caracteres e um `length` de 6. **O `length` conta unidades de código UTF-16, e o
emoji do fim ocupa duas delas**, `d83d` e `dc4b`, como mostra o `split("")`. O iterador de uma
string anda por **ponto de código**, então `[...word]` tem cinco itens e o emoji é um deles. Se você
precisa contar ou inverter o que um leitor vê como caracteres, espalhe a string antes; o `split("")`
corta alguns ao meio.
