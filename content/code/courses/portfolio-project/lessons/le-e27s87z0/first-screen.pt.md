---
title: A primeira tela
version: 1
---

Quem avalia e abre um repositório vê a primeira tela do README antes de decidir se rola a página. Essa tela
precisa fazer três coisas, e a do loanbook faz em doze linhas:

```
ana@laptop:~/loanbook$ head -12 README.md
# loanbook

The IT room of a secondary school lends projectors, laptops and adapters to
teachers, and the record of who had what was a paper sheet taped to the door.
loanbook replaces the sheet with one page: what is out, who has it, and when
it is due back.

![The list: four items out, one of them overdue](docs/screenshot.png)

## What it does

- Lists the equipment, and for each item on loan, who has it and until when.
```

**Um parágrafo que diz o que é e para quem**, nas palavras do problema, não da tecnologia. *Uma página que
mostra o que está fora, com quem e quando volta* é entendida por quem nunca programou. *Uma API REST em
Python com persistência em SQLite* só é entendida por quem já sabe para que você a construiu, ou seja,
ninguém ainda.

**Uma imagem dele funcionando.** Uma captura de tela é a evidência mais rápida que existe: antes de ler uma
linha de código, quem avalia já viu a lista, os quatro empréstimos e o atrasado. O texto `alt` dela diz o
que mostra, para quem não consegue ver e para o momento em que a imagem não carrega. A aula 17 trata de
tirar uma que mostre a coisa certa.

**O caminho de entrada**, que no loanbook é o título seguinte. Um projeto com endereço no ar o põe aqui, na
segunda linha, como link; o do loanbook mora no laboratório, então a primeira tela não diz nada sobre ele
em vez de imprimir um endereço que quem lê não consegue abrir.

O que **não** está na primeira tela importa tanto quanto: nada de selos, de sumário, de passos de
instalação, de história de como a ideia surgiu. Cada um empurra o parágrafo e a imagem para baixo da dobra,
onde a maioria dos leitores nunca vai.
