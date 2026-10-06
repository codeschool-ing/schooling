---
title: WeakMap: anotações presas a objetos
version: 1
---

**Um `WeakMap` é um `Map` cujas chaves precisam ser objetos, e que não mantém as chaves vivas.** A
segunda metade dessa frase é o assunto da última seção; esta é sobre o que isso deixa você fazer.
A interface é a conhecida, menos tudo o que percorreria as entradas:

```javascript
const visits = new WeakMap();
const reader = { name: "ana" };

visits.set(reader, 1);
visits.set(reader, visits.get(reader) + 1);
console.log(visits.get(reader), visits.has(reader));
console.log(visits.size, typeof visits.keys);

visits.set("ana", 1);
```

```
ana@dev:~/js$ node weakmap.js 2>&1 | head -n 7
2 true
undefined undefined
/home/ana/js/weakmap.js:9
visits.set("ana", 1);
       ^

TypeError: Invalid value used as weak map key
```

`set`, `get`, `has` e `delete` funcionam. **Não existe `size` nem `keys`**, e um `WeakMap` não pode
ser percorrido num laço. Uma chave string é recusada com um `TypeError`, porque uma string não é um
objeto. As duas restrições vêm do mesmo lugar: as entradas podem sumir a qualquer momento, então
não existe uma lista estável para contar ou percorrer.

## Para que serve

**Um `WeakMap` prende informação a um objeto sem colocá-la no objeto.** Dois usos comuns:

- **um cache** indexado por um objeto, como o tamanho medido de cada elemento de uma página, ou o
  resultado de um cálculo caro por documento. Quando o objeto vai embora, a entrada dele no cache
  vai junto, e ninguém precisa lembrar de apagá-la;
- **dados que o dono do objeto não deve ver**, guardados ao lado do objeto e não dentro dele:

```javascript
const balances = new WeakMap();

function openAccount(owner) {
  const account = { owner };
  balances.set(account, 0);
  return account;
}

function deposit(account, cents) {
  balances.set(account, balances.get(account) + cents);
}

function balance(account) {
  return balances.get(account);
}

const acc = openAccount("ana");
deposit(acc, 1990);
deposit(acc, 500);
console.log(acc, balance(acc));
```

```
{ owner: 'ana' } 2490
```

`acc` saiu como `{ owner: 'ana' }`: **o saldo não está no objeto.** Só o código que alcança
`balances` consegue lê-lo, o que aqui são as três funções. A aula 8 mostra a sintaxe de classe para
a mesma ideia, os campos privados, que é o que você escreveria hoje; este padrão é o que as
bibliotecas usavam antes de eles existirem, e o que você ainda usa para anotar objetos criados por
outra pessoa, como os elementos de uma página.
