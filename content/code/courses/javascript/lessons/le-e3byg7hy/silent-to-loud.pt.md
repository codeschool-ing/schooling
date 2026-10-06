---
title: Falhas silenciosas que viram erros
version: 1
---

Vários tipos de atribuição não podem acontecer: a propriedade é somente leitura, o objeto está
congelado, o valor é um primitivo. **O modo não estrito os ignora sem uma palavra; o modo estrito lança
um `TypeError`.** Quatro deles, primeiro num arquivo não estrito:

```javascript
const frozen = Object.freeze({ title: "Iracema" });
frozen.title = "Ubirajara";
console.log(frozen.title);

class Account {
  #cents = 1990;
  get balance() { return this.#cents; }
}
const acc = new Account();
acc.balance = 5;
console.log(acc.balance);

"Iracema".year = 1865;
console.log(delete Object.prototype);
```

```
ana@dev:~/js$ node silent.js
Iracema
1990
false
```

O título ficou `Iracema`, o saldo ficou `1990`, a string não ganhou `year`, e o `delete` só respondeu
`false`. **Toda linha rodou, nada mudou, e nada disse isso.** O saldo só com getter é o que a aula 8
deixou para esta aula: `acc.balance = 5` foi ignorado lá exatamente por esse motivo.

Os mesmos quatro, num ES module, que é estrito:

```javascript
const attempts = {
  "assign to a frozen object": () => { Object.freeze({ title: "Iracema" }).title = "Ubirajara"; },
  "assign to a getter-only property": () => {
    class Account { get balance() { return 1990; } }
    new Account().balance = 5;
  },
  "set a property on a string": () => { "Iracema".year = 1865; },
  "delete Object.prototype": () => { delete Object.prototype; },
};
for (const [what, attempt] of Object.entries(attempts)) {
  try {
    attempt();
    console.log(`${what}: silently ignored`);
  } catch (err) {
    console.log(`${what}: ${err.name}: ${err.message}`);
  }
}
```

```
ana@dev:~/js$ node loud.mjs
assign to a frozen object: TypeError: Cannot assign to read only property 'title' of object '#<Object>'
assign to a getter-only property: TypeError: Cannot set property balance of #<Account> which has only a getter
set a property on a string: TypeError: Cannot create property 'year' on string 'Iracema'
delete Object.prototype: TypeError: Cannot delete property 'prototype' of function Object() { [native code] }
```

Cada um lançou erro, e **cada mensagem diz exatamente o que não pôde ser feito**: a propriedade
congelada é somente leitura, a propriedade só tem getter, uma string não aceita propriedade, o
`prototype` não pode ser apagado. São bugs de qualquer jeito. A diferença é se você os acha na linha
que os fez ou, depois, por um valor que não é o que você definiu.

## `Object.freeze`

A primeira linha vale saber por si só. **`Object.freeze(obj)` torna as propriedades de um objeto
somente leitura e impede que novas sejam acrescentadas.** Ele é raso, como o spread da aula 4: um
objeto congelado que guarda um array ainda guarda um array que pode mudar. É útil para constantes e
configuração que nada deve mudar, e em código estrito uma tentativa de mudar uma falha fazendo
barulho.
