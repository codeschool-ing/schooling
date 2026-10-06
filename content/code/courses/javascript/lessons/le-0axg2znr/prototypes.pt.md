---
title: Todo objeto tem um protótipo
version: 1
---

**Um objeto pode ter um vínculo com outro objeto, chamado protótipo.** Quando você lê uma
propriedade que o objeto não tem, o JavaScript não desiste: procura no protótipo, e devolve o que
achar lá. `Object.create` cria um objeto novo com o protótipo que você escolher, o que o torna o
jeito mais claro de ver isso:

```javascript
const reader = {
  greet() {
    return `hello from ${this.name}`;
  },
};

const ana = Object.create(reader);
ana.name = "ana";

console.log(ana.greet());
console.log(Object.getPrototypeOf(ana) === reader);
console.log(Object.hasOwn(ana, "greet"), "greet" in ana);
console.log(ana);

ana.greet = () => "my own greeting";
console.log(ana.greet());
delete ana.greet;
console.log(ana.greet());
```

```
ana@dev:~/js$ node proto.js
hello from ana
true
false true
{ name: 'ana' }
my own greeting
hello from ana
```

- `ana` foi criada vazia, com `reader` como protótipo, e depois recebeu um `name`. **`ana.greet()`
  funcionou embora `ana` não tenha `greet`**: a busca o achou em `reader`;
- dentro de `greet`, `this` era `ana`, não `reader`. O método foi achado no protótipo, **mas foi
  chamado em `ana`**, e a regra da aula 6, o objeto antes do ponto, continua decidindo o `this`;
- `Object.hasOwn` diz que `greet` não é propriedade própria de `ana`, enquanto o `in` diz que dá
  para alcançá-la. Imprimir `ana` mostra só as propriedades próprias, `{ name: 'ana' }`;
- dar a `ana` o seu próprio `greet` **sombreou** o do protótipo; apagá-lo descobriu o herdado de
  novo.

## Ler é herdado, escrever não

```javascript
const reader = { shelves: [] };
const ana = Object.create(reader);
const bia = Object.create(reader);

ana.shelves.push("Romance");
console.log(bia.shelves);

bia.shelves = ["Poetry"];
console.log(ana.shelves, bia.shelves);
```

```
ana@dev:~/js$ node shared.js
[ 'Romance' ]
[ 'Romance' ] [ 'Poetry' ]
```

`ana.shelves.push("Romance")` **leu** `shelves`, achou o array no protótipo e mudou esse array. `bia`
lê o mesmo, então viu "Romance" também. `bia.shelves = ["Poetry"]` é uma **escrita**, e uma escrita
sempre vai no próprio objeto, então deu a `bia` uma propriedade própria e deixou a do protótipo em
paz.

Essa é a regra a levar. **Buscas sobem a cadeia; atribuições ficam no objeto.** É também por isso
que um protótipo deve guardar métodos, que são compartilhados de propósito, e não dados de que cada
objeto precisa ter a sua própria cópia. Toda classe desta aula segue essa divisão.
