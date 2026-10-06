---
title: throw, e por que lançar um Error
version: 1
---

**O `throw` interrompe a função atual e entrega um valor a quem puder pegá-lo.** Nada depois do
`throw` roda, naquela função ou em qualquer chamador que não o pegue:

```javascript
function lend(book, copies) {
  if (copies < 1) {
    throw new RangeError(`cannot lend ${copies} copies of ${book}`);
  }
  return `${copies} x ${book}`;
}

function checkout() {
  console.log(lend("Iracema", 1));
  console.log(lend("Dom Casmurro", 0));
  console.log("never reached");
}

checkout();
```

```
ana@dev:~/js$ node throw.js 2>&1 | head -n 9
1 x Iracema
/home/ana/js/throw.js:3
    throw new RangeError(`cannot lend ${copies} copies of ${book}`);
    ^

RangeError: cannot lend 0 copies of Dom Casmurro
    at lend (/home/ana/js/throw.js:3:11)
    at checkout (/home/ana/js/throw.js:10:15)
    at Object.<anonymous> (/home/ana/js/throw.js:14:1)
```

A primeira chamada funcionou. A segunda lançou erro, e **`never reached` nunca foi alcançado**: o throw
saiu de `lend`, depois de `checkout`, depois do arquivo, e sem ninguém para pegá-lo o Node imprimiu o
erro e parou. Leia a pilha embaixo da mensagem de cima para baixo, como a aula 13 mostrou: o erro veio
de `lend` na linha 3, chamada por `checkout` na linha 10.

## Lance um `Error`, não uma string

A linguagem deixa você lançar qualquer valor. **Só um objeto `Error` registra onde foi feito**:

```javascript
function lend(copies) {
  if (copies < 1) throw "no copies";
}
try {
  lend(0);
} catch (err) {
  console.log(typeof err, err, err.stack);
}
try {
  lend2(0);
} catch (err) {
  console.log(typeof err, err.name, "|", err.message);
}
function lend2(copies) {
  if (copies < 1) throw new Error("no copies");
}
```

```
ana@dev:~/js$ node throw-string.js
string no copies undefined
object Error | no copies
```

A string lançada chegou como string, sem `stack`, então nada diz que linha a lançou. O `Error` tem um
`name`, uma `message` e, embora não impressa aqui, uma `stack` capturada no momento em que foi criado.
**Todo erro embutido e toda biblioteca lançam objetos `Error`**, e código que pega espera um; uma
string quebra todo `err.message` que alcança.

## Quando uma função deve lançar erro

Uma função lança erro quando **não consegue fazer o seu trabalho e devolver algo seria mentira**:
emprestar zero cópias, interpretar texto que não é JSON, ler um arquivo que não existe. Uma função que
procura algo e não acha pode muito bem devolver `null` ou `undefined`, quando "não achei" é uma
resposta comum. O teste é se quem chama consegue seguir em frente com o valor devolvido. Se seguir em
frente seria errado, lance erro.
