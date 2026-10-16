---
title: O Console, e os erros que um teste não deve ignorar
version: 1
---

A aba **Console** faz dois trabalhos. Mostra o que a página escreve, as mensagens dela e as queixas
do navegador sobre ela, e roda qualquer JavaScript que você digitar, dentro da página, contra o DOM
vivo. Um testador usa o segundo trabalho para fazer perguntas e o primeiro para notar o que ninguém
perguntou.

## Fazendo perguntas à página

Digite isto no Console da página da loja e aperte Enter:

```javascript
document.querySelectorAll('#products li').length
```

A resposta é `8`, um para cada produto de `app/store.js`. Qualquer expressão funciona ali, e o
Console oferece duas formas curtas próprias: `$$('button')` lista todo elemento que um seletor CSS
encontra, e `$0` é o elemento selecionado no momento no painel Elements. Perguntar à página
*quantos destes existem, agora?* antes de escrever um teste é a mesma verificação da caixa de busca
do painel Elements, com a linguagem inteira por trás.

## Uma página que falha calada

A maioria das páginas quebradas não parece quebrada. Esta é a loja com um erro que acontece o tempo
todo num projeto montado copiando arquivos: o script foi salvo como `App.js`, com A maiúsculo, e a
página pede `app.js`. O `look.mjs` a carrega:

```
ana@laptop:~/quitanda$ node look.mjs
   12 ms  200 GET /  (document)
   21 ms  200 GET /style.css  (stylesheet)
   23 ms  404 GET /app.js  (script)
   23 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
```

Na tela, o título e a cesta vazia aparecem e a lista nunca se preenche: nada diz *erro*. A linha da
rede diz `404`, e o Console traz a queixa do próprio navegador, **Failed to load resource**. No
Windows e no macOS, cujos discos costumam ignorar maiúsculas e minúsculas no nome de um arquivo, o
mesmo erro funciona no seu computador e quebra num servidor Linux.

Agora o arquivo voltou, mas um endereço dentro dele está errado: `/api/product`, sem o `s`:

```
ana@laptop:~/quitanda$ node look.mjs
   14 ms  200 GET /  (document)
   22 ms  200 GET /style.css  (stylesheet)
   23 ms  200 GET /app.js  (script)
   51 ms  404 GET /api/product  (fetch)
   54 ms  console.error: Failed to load resource: the server responded with a status of 404 (Not Found)
   56 ms  uncaught error: Unexpected token 'o', "not found" is not valid JSON
```

Três linhas descrevem um defeito, e cada uma é uma evidência de tipo diferente. O servidor respondeu
`404`. O navegador registrou a requisição que falhou. E o script, que esperava JSON, tentou ler
`not found` como JSON e **lançou um erro que ninguém tratou**. No Console essa última linha é
vermelha e diz *Uncaught*. Na tela, de novo, uma lista vazia.

## Por que um teste deve escutar

Um teste que confere só o que consegue ver relataria a primeira dessas páginas como *a lista está
vazia* e pararia aí, o que é verdade e não ajuda. A linha do console e o erro não tratado dizem
**por quê**, na mesma execução, sem custo. O Playwright entrega os dois a um teste, como os eventos
`console` e `pageerror` que o `look.mjs` escuta, e a aula 16 os transforma nas evidências que um
teste que falha deixa para trás.

Há uma posição mais forte, e muitas equipes a adotam: **um erro não tratado numa página reprova o
teste que o viu**, pareça certo ou não o que o teste confere. Uma página pode lançar um erro e ainda
desenhar o título; um teste que ignora isso passa numa página quebrada. Onde traçar essa linha é uma
decisão, e o Console é de onde vem a evidência para tomá-la.
