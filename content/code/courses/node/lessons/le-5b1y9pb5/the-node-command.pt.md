---
title: O comando node
version: 1
---

**O `node` roda um arquivo, uma expressão ou uma conversa**, e você vai usar os três. O arquivo é o
caso comum. Este é o `~/server/cmd/sum.js`:

```javascript
// sum.js
const prices = [12.5, 7.25, 30];
let total = 0;
for (const price of prices) total += price;
console.log(`${prices.length} items, ${total} in total`);
```

```
ana@dev:~/server/cmd$ node sum.js
3 items, 49.75 in total
ana@dev:~/server/cmd$ node -p "2 ** 53"
9007199254740992
ana@dev:~/server/cmd$ node -p "2 ** 53 + 1"
9007199254740992
ana@dev:~/server/cmd$ node -e 'console.log(new Date(0).toISOString())'
1970-01-01T00:00:00.000Z
```

`node ARQUIVO` roda o arquivo de cima a baixo e para quando não sobra nada para fazer. Um servidor
nunca fica sem o que fazer, porque uma porta aberta é algo a esperar; a aula 2 trata exatamente de
quando um processo decide que terminou. **`node -p`** avalia uma expressão e a imprime, e
**`node -e`** roda código e não imprime nada, a não ser que o código imprima. Os dois servem para
conferir um fato sem escrever um arquivo. As duas linhas acima deles mostram um que vale saber:
passando de 2 elevado a 53, um número em JavaScript não consegue mais contar de um em um, então somar
um não muda nada.

## A conversa

O `node` sem nada depois abre o **REPL**, de read, evaluate, print and loop. Ele lê uma linha, roda,
imprime o valor e pergunta de novo:

```
ana@dev:~/server/cmd$ node
Welcome to Node.js v22.22.0.
Type ".help" for more information.
> 1 + 2
3
> const s = "olá"
undefined
> s.length
3
> Buffer.byteLength(s)
4
> .exit
```

Um `const` imprime `undefined` porque uma declaração não tem valor; o nome passa a existir para as
linhas seguintes. As duas últimas linhas são uma diferença sobre a qual a aula 8 é construída:
**`"olá"` tem três caracteres e quatro bytes**, porque o `á` ocupa dois bytes em UTF-8. `.exit`, ou
Ctrl-D, sai. O REPL é o jeito mais rápido de testar algo, e nada digitado nele fica salvo onde você
vá encontrar de novo, então o que funcionar vai para um arquivo.

## Conferir sem rodar

O `node --check` lê um arquivo procurando erros de sintaxe e não roda nada dele. Aqui está ele no
`sum.js` e num arquivo com um colchete faltando:

```javascript
// broken.js
const prices = [12.5, 7.25, 30;
console.log(prices);
```

```
ana@dev:~/server/cmd$ node --check sum.js; echo $?
0
ana@dev:~/server/cmd$ node --check broken.js; echo $?
/home/ana/server/cmd/broken.js:2
const prices = [12.5, 7.25, 30;
                              ^

SyntaxError: Unexpected token ';'
    at wrapSafe (node:internal/modules/cjs/loader:1638:18)
    at checkSyntax (node:internal/main/check_syntax:78:3)

Node.js v22.22.0
1
```

**`$?` é o código de saída do último comando**: `0` quer dizer que deu certo, e qualquer outra coisa
quer dizer que não deu. Todo programa deste curso termina com um, e a próxima seção mostra de onde
vem o de uma queda. Um servidor que você está para reiniciar é um bom motivo para rodar o `--check`
antes: um erro de digitação então custa uma mensagem em vez de um serviço parado.
