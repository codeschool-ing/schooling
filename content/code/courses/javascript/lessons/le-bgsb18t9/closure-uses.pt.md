---
title: Para que servem as closures
version: 1
---

Closures não são uma curiosidade para saber; **são como o JavaScript guarda estado que pertence a
uma função**, sem classe e sem global. Três padrões cobrem quase tudo o que você vai escrever e ler.

## Rodar algo uma vez

```schooling-example
{
  "language": "javascript",
  "file": "once.js",
  "parts": [
    {
      "code": "function once(fn) {\n  let done = false;\n  let result;",
      "note": "`once` recebe uma função e devolve uma nova. As duas variáveis `let` vivem no escopo desta chamada de `once`, e só a arrow devolvida as alcança."
    },
    {
      "code": "  return (...args) => {",
      "note": "A função devolvida aceita quaisquer argumentos com um parâmetro rest, então pode ficar no lugar de qualquer função."
    },
    {
      "code": "    if (!done) {\n      done = true;\n      result = fn(...args);\n    }\n    return result;\n  };\n}",
      "note": "A primeira chamada roda `fn` e lembra o resultado. Toda chamada seguinte vai direto devolver esse resultado."
    },
    {
      "code": "const connect = once(() => {\n  console.log(\"connecting...\");\n  return \"connection 1\";\n});\n\nconsole.log(connect());\nconsole.log(connect());\nconsole.log(connect());",
      "note": "`connect` é a função embrulhada. A mensagem dentro dela saiu uma vez, embora `connect` tenha sido chamada três vezes."
    }
  ],
  "output": "connecting...\nconnection 1\nconnection 1\nconnection 1"
}
```

Uma conexão, uma inicialização, um aviso mostrado ao usuário: **coisas que precisam acontecer uma
vez, não importa quantos lugares as peçam**. O estado é `done` e `result`, e nada de fora consegue
zerá-los sem querer.

## Lembrar respostas

```javascript
function memoize(fn) {
  const cache = new Map();
  return (n) => {
    if (cache.has(n)) return cache.get(n);
    const value = fn(n);
    cache.set(n, value);
    return value;
  };
}

let calls = 0;
const slowSquare = (n) => {
  calls = calls + 1;
  return n * n;
};

const square = memoize(slowSquare);
console.log(square(12), square(12), square(5), square(12));
console.log("slowSquare ran", calls, "times");
```

```
ana@dev:~/js$ node memo.js
144 144 25 144
slowSquare ran 2 times
```

`memoize` captura um `Map` (aula 5) de respostas já calculadas. **`square(12)` foi pedido três vezes
e calculado uma**, o que o contador confirma: `slowSquare ran 2 times`, uma para 12 e uma para 5. Só
vale a pena para uma função que seja lenta e sempre dê a mesma resposta para a mesma entrada.

## Estado privado

```javascript
function makeAccount(owner) {
  let balanceCents = 0;
  return {
    owner,
    deposit(cents) {
      if (cents <= 0) throw new RangeError("a deposit must be positive");
      balanceCents += cents;
    },
    balance() {
      return balanceCents;
    },
  };
}

const acc = makeAccount("ana");
acc.deposit(1990);
acc.balanceCents = 1000000;
console.log(acc.balance(), acc.balanceCents);
```

```
ana@dev:~/js$ node account.js
1990 1000000
```

`balanceCents` vive na closure, e o objeto devolvido tem métodos que a alcançam.
**`acc.balanceCents = 1000000` criou uma propriedade nova e sem relação no objeto** e não mudou nada
que importa: `balance()` ainda respondeu 1990. O único jeito de mudar o saldo é `deposit`, que pode
recusar um valor sem sentido. A aula 8 mostra a sintaxe de classe para a mesma garantia, os campos
privados; este padrão com closure é o que ela substituiu, e você vai encontrá-lo em bibliotecas
mais antigas e em módulos pequenos em que uma classe seria demais.
