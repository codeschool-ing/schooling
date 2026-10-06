---
title: this numa chamada sozinha
version: 1
---

A aula 6 disse que uma chamada sozinha dá `undefined` para `this` no modo estrito e prometeu a outra
metade. Aqui está:

```javascript
function sloppyThis() {
  return this === globalThis;
}
function strictThis() {
  "use strict";
  return this;
}
console.log(sloppyThis(), strictThis());
```

```
ana@dev:~/js$ node this-check.js
true undefined
```

**No modo não estrito, uma função chamada sozinha recebe o objeto global como `this`**; no modo
estrito recebe `undefined`. Essa diferença decide como um método perdido falha:

- em código estrito, `this.prefix` em `undefined` lança erro na hora: `Cannot read properties of
  undefined`, a mensagem que a aula 6 ensinou você a ler como "este método perdeu o seu objeto";
- em código não estrito, `this.prefix` lê uma propriedade do objeto global, que quase sempre é
  `undefined`, e o método segue e produz `undefined: Iracema`, como fez o `withFunction` da aula 6.
  **Pior, uma atribuição como `this.count = 0` cria um global**, então um método perdido pode mudar em
  silêncio um estado que todo outro script compartilha.

O modo estrito transforma um `this` perdido de resultado errado em erro na chamada. Classes são
estritas, então um método de classe que perde o seu objeto sempre falha do jeito barulhento, e esse é
um motivo de as classes terem tornado este bug mais fácil de achar.
