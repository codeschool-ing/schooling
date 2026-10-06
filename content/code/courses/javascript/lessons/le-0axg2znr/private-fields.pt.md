---
title: Campos, campos privados e campos arrow
version: 1
---

Um corpo de classe pode declarar **campos**: propriedades que toda instância recebe, escritas uma vez
no topo em vez de dentro do construtor. Um campo cujo nome começa com `#` é **privado**, alcançável
só por código dentro do corpo da classe:

```javascript
class Account {
  #balanceCents = 0;
  static #opened = 0;

  constructor(owner) {
    this.owner = owner;
    Account.#opened += 1;
  }

  deposit(cents) {
    if (cents <= 0) throw new RangeError("a deposit must be positive");
    this.#balanceCents += cents;
  }

  get balance() {
    return this.#balanceCents;
  }

  static count() {
    return Account.#opened;
  }

  static isAccount(value) {
    return #balanceCents in value;
  }
}

const acc = new Account("ana");
acc.deposit(1990);
console.log(acc.balance, Account.count());
console.log(acc, Object.keys(acc), JSON.stringify(acc));
acc.balance = 5;
console.log(acc.balance);
console.log(Account.isAccount(acc), Account.isAccount({ owner: "bia" }));
```

```
ana@dev:~/js$ node private.js
1990 1
Account { owner: 'ana' } [ 'owner' ] {"owner":"ana"}
1990
true false
```

- `#balanceCents = 0` dá a toda conta o seu próprio saldo, e **nada fora da classe o vê**. Imprimir
  `acc` mostra só `owner`; `Object.keys` e `JSON.stringify` não o listam;
- `get balance()` deixa o lado de fora lê-lo. `acc.balance = 5` tentou escrevê-lo e **foi
  ignorado**: um getter sem setter não aceita atribuição. Este arquivo não é estrito, então foi
  ignorado em silêncio; a aula 20 mostra a mesma linha lançando erro no modo estrito;
- `static #opened` é privado da própria classe, e conta as contas;
- **`#balanceCents in value` pergunta se um objeto foi feito por esta classe**, uma conferência que
  um objeto apenas parecido com uma conta não engana.

## Privacidade garantida antes de o programa rodar

```javascript
class Account {
  #balanceCents = 0;
}
const acc = new Account();
console.log(acc.#balanceCents);
```

```
ana@dev:~/js$ node peek.js 2>&1 | head -n 5
/home/ana/js/peek.js:5
console.log(acc.#balanceCents);
               ^

SyntaxError: Private field '#balanceCents' must be declared in an enclosing class
```

**Ler um campo privado de fora é um `SyntaxError`**, encontrado enquanto o arquivo é lido, então o
programa nem começa. É uma garantia mais forte que o padrão com closure da aula 6 ou o `WeakMap` da
aula 5, que escondiam dados deixando-os fora de alcance. Campos privados são o que se escreve hoje;
você vai encontrar os outros dois em código escrito antes de 2022, quando eles viraram padrão.

## Campos arrow mantêm o seu `this`

Um campo pode guardar uma função. **Uma arrow function num campo captura a instância como o seu
`this`**, porque o valor do campo é criado enquanto o construtor roda:

```javascript
"use strict";

class Counter {
  count = 0;
  increment = () => {
    this.count += 1;
    return this.count;
  };
}

const c = new Counter();
const press = c.increment;
press();
press();
console.log(c.count, Object.hasOwn(c, "increment"));
console.log(new Counter().increment === c.increment);
```

```
ana@dev:~/js$ node field-arrow.js
2 true
false
```

`press` é `c.increment` tirado do seu ponto, exatamente o erro da aula 6, e funcionou duas vezes.
Esta é a forma mais curta do bind no construtor da aula 7, com a mesma consequência: **cada instância
ganha a sua própria cópia da função**, e não uma compartilhada no protótipo, o que a última linha
mostra. Isso custa um pouco de memória por objeto, e compra um handler que você passa para qualquer
lugar e remove depois com a mesma referência.
