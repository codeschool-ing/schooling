---
title: Quando a instalação falha
version: 1
---

**A maioria das falhas do primeiro dia é uma de quatro mensagens**, e cada uma diz exatamente o que
está errado quando você sabe lê-la. Esta seção é para o momento em que algo não funciona, então
mostra cada mensagem antes de explicá-la.

## `command not found`

```
ana@dev:~/js$ PATH=/usr/bin:/bin node --version
bash: line 1: node: command not found
```

O shell procurou um programa chamado `node` em cada diretório do seu `PATH`, a lista de lugares
onde ele procura, e não achou nenhum. O laboratório encena isso rodando um comando com um `PATH`
que deixa o Node de fora. No seu computador significa uma de duas coisas: **o Node nunca foi
instalado, ou foi instalado e o terminal foi aberto antes de o instalador terminar.** Feche o
terminal e abra outro antes de reinstalar qualquer coisa; um terminal lê o `PATH` uma vez, quando
começa.

## `Cannot find module`

```
ana@dev:~/js$ node helo.js
node:internal/modules/cjs/loader:1386
  throw err;
  ^

Error: Cannot find module '/home/ana/js/helo.js'
    at Function._resolveFilename (node:internal/modules/cjs/loader:1383:15)
    at defaultResolveImpl (node:internal/modules/cjs/loader:1025:19)
    at resolveForCJSWithHooks (node:internal/modules/cjs/loader:1030:22)
    at Function._load (node:internal/modules/cjs/loader:1192:37)
    at TracingChannel.traceSync (node:diagnostics_channel:328:14)
    at wrapModuleLoad (node:internal/modules/cjs/loader:237:24)
    at Function.executeUserEntryPoint [as runMain] (node:internal/modules/run_main:171:5)
    at node:internal/main/run_main_module:36:49 {
  code: 'MODULE_NOT_FOUND',
  requireStack: []
}

Node.js v22.22.0
```

Comprida, e só uma linha importa: `Error: Cannot find module '/home/ana/js/helo.js'`. **O Node está
dizendo o caminho completo que tentou**, e o arquivo se chama `hello.js`. Tudo o que vem recuado
embaixo é o código do próprio Node a caminho desse erro; dá para ignorar até a aula 17 ensinar a
ler uma pilha. As duas causas comuns são um erro de digitação, como aqui, e um terminal parado num
diretório diferente do arquivo. `pwd` diz onde você está, `ls` o que tem ali.

## `Invalid or unexpected token`

Um arquivo colado de um editor de texto ou de uma janela de chat costuma trazer aspas tipográficas,
`“` e `”`, onde a linguagem quer o `"` simples:

```javascript
console.log(“Hello”);
```

```
ana@dev:~/js$ node quotes.js 2>&1 | head -n 5
/home/ana/js/quotes.js:1
console.log(“Hello”);
            

SyntaxError: Invalid or unexpected token
```

O `2>&1 | head -n 5` no fim mantém as cinco primeiras linhas; o resto é a mesma lista de internos
do Node de antes. **Um token é uma palavra da linguagem**, e `“` não é uma. O Node diz o arquivo e
a linha, `quotes.js:1`, e é ali que se olha. Redigite as aspas no seu editor.

## `Unexpected token '<'`

```
ana@dev:~/js$ node hello.html 2>&1 | head -n 5
/home/ana/js/hello.html:1
<!doctype html>
^

SyntaxError: Unexpected token '<'
```

**O Node recebeu uma página em vez de um programa.** `<` é onde o HTML começa e o JavaScript não. A
página vai para um navegador, ou para `page` no laboratório; só o arquivo `.js` vai para o `node`.

## Uma versão antiga demais

Uma máquina com um Node antigo instalado, de um projeto de anos atrás ou de um pacote do sistema,
roda a maior parte deste curso e depois falha numa sintaxe mais nova com um `SyntaxError`. Isso não
foi rodado no laboratório, que tem o Node 22. A conferência é a de cima, `node --version`: este
curso foi gravado no 22, e algumas aulas usam recursos que chegaram nele, então instale o 22 ou
mais novo.
