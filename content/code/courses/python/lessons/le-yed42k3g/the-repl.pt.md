---
title: O prompt que responde
version: 1
---

Digite `python3` sem nome de arquivo e você ganha um prompt:

```
Python 3.12.3
>>> 
```

Isto é o **REPL** — *read, evaluate, print, loop*: lê, avalia, imprime, repete. Você digita uma
expressão, ele avalia e mostra a resposta, e volta a esperar.

```
>>> 2 + 2
4
>>> "ada".upper()
'ADA'
>>> len("hello")
5
```

Repare que ele imprimiu sem ninguém pedir. Num arquivo é preciso `print`; no prompt, o valor do que
você digitou é mostrado. Essa diferença pega todo mundo uma vez.

## Três coisas que valem saber

**`_` é o último valor.**

```
>>> 17 * 3
51
>>> _ + 1
52
```

**`help()` lê a documentação para você.** `help(len)` imprime o que o `len` faz e o que ele recebe.
`help(str.upper)` faz o mesmo para um método. Funciona com qualquer coisa, inclusive com o que você
escreveu.

**`dir()` lista o que existe.** `dir("")` mostra todo método que uma string tem. É uma lista longa e
não é para ser decorada; ela serve para o momento em que você pensa *tem de haver alguma coisa que
faça isso* — e você tem razão.

## Saindo

`exit()` ou `quit()`, ou `Ctrl-D` no macOS e no Linux, `Ctrl-Z` e Enter no Windows.

## Quando ele é a ferramenta errada

O REPL é para uma **pergunta**. O que este método devolve, isto é lista ou tupla, o que acontece se a
string estiver vazia.

Ele é o lugar errado para **trabalho**, por um motivo que não é de preferência: nada do que você
digita ali sobrevive a fechar a janela. O que você vai querer amanhã, ou rodar duas vezes, vai num
arquivo. É a próxima seção, e é o único hábito desta aula que ainda importa daqui a seis meses.
