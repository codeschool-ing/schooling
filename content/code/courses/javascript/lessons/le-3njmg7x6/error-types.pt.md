---
title: Os tipos de erro
version: 1
---

A linguagem lança um punhado de subclasses de `Error`, e **o nome diz que tipo de erro foi**, o que
muitas vezes basta para saber onde olhar:

```javascript
const attempts = [
  () => null.title,
  () => undefinedName,
  () => new Array(-1),
  () => JSON.parse("{oops"),
  () => decodeURIComponent("%"),
];
for (const attempt of attempts) {
  try {
    attempt();
  } catch (err) {
    console.log(err.constructor.name.padEnd(14), err instanceof Error, "|", err.message);
  }
}
```

```
ana@dev:~/js$ node types.js
TypeError      true | Cannot read properties of null (reading 'title')
ReferenceError true | undefinedName is not defined
RangeError     true | Invalid array length
SyntaxError    true | Expected property name or '}' in JSON at position 1 (line 1 column 2)
URIError       true | URI malformed
```

| nome | significa | você o encontrou em |
|---|---|---|
| **`TypeError`** | um valor do tipo errado: chamar algo que não é função, ler propriedade de `null` | aulas 1, 4, 6 |
| **`ReferenceError`** | um nome que não existe, ou está na zona morta | aulas 1, 3 |
| **`RangeError`** | um número fora do permitido, ou uma pilha que acabou | aulas 7, 13 |
| **`SyntaxError`** | código ou JSON que não dá para interpretar | aulas 1, 9, 16 |
| `URIError` | um escape malformado numa URL | aqui |

Todos são `instanceof Error`, que é o que o código confere quando quer ter certeza de que pegou um erro
de verdade.

## Os seus próprios erros

**Estender `Error` dá às falhas do seu programa nomes próprios**, para quem chama distingui-las:

```javascript
class LoanError extends Error {
  constructor(message, options) {
    super(message, options);
    this.name = "LoanError";
  }
}

class OverdueError extends LoanError {
  constructor(reader, days) {
    super(`${reader} has a book ${days} days overdue`);
    this.name = "OverdueError";
    this.reader = reader;
    this.days = days;
  }
}

function lend(reader) {
  if (reader === "bia") throw new OverdueError("bia", 12);
  try {
    JSON.parse("{not json");
  } catch (err) {
    throw new LoanError(`could not read ${reader}'s card`, { cause: err });
  }
}

for (const reader of ["bia", "ana"]) {
  try {
    lend(reader);
  } catch (err) {
    console.log(err.name, err instanceof LoanError, err instanceof OverdueError, "|", err.message);
    if (err.cause) console.log("  caused by:", err.cause.name, "|", err.cause.message);
    if (err instanceof OverdueError) console.log("  days:", err.days);
  }
}
```

```
ana@dev:~/js$ node custom.js
OverdueError true true | bia has a book 12 days overdue
  days: 12
LoanError true false | could not read ana's card
  caused by: SyntaxError | Expected property name or '}' in JSON at position 1 (line 1 column 2)
```

- `LoanError` é a família e `OverdueError` um membro, então **o `instanceof` responde nos dois
  níveis**: o erro de atraso era os dois;
- definir `this.name` é o que faz o nome aparecer em mensagens e rastros de pilha; sem isso, todo erro
  personalizado se chamaria `Error`;
- `OverdueError` leva **dados**, `reader` e `days`, para quem chama agir sobre eles em vez de
  interpretar a mensagem, que é escrita para pessoas e pode mudar;
- o segundo leitor falhou por outro motivo por baixo, um cartão que não era JSON válido. **A opção
  `cause` mantém o erro original preso**, para a mensagem falar em termos de empréstimos enquanto a
  causa diz exatamente o que quebrou.
