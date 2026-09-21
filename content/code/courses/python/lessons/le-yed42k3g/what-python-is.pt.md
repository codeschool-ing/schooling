---
title: Um interpretador lê o seu arquivo, uma linha por vez
version: 1
---

Você escreve um arquivo. Um programa chamado **interpretador** lê esse arquivo e faz o que ele diz.
É esse o arranjo inteiro, e o nome do interpretador do Python é `python3`.

Algumas linguagens fazem diferente. C e Go são **compiladas**: um programa à parte transforma o seu
arquivo em instruções de máquina uma vez, e o que você distribui é o resultado. Python é
**interpretada**: não existe resultado à parte, e o `python3` lê o seu arquivo toda vez que ele roda.

## O que isso compra

**Dá para rodar um programa pela metade.** O interpretador lê até o ponto onde quebra e avisa, o que
significa descobrir a linha 4 sem precisar deixar a linha 40 correta antes. Numa linguagem compilada
nada roda enquanto tudo não compilar.

**E dá para conversar com ele direto**, que é a próxima seção.

## O que custa

**Velocidade.** Um laço que soma dez milhões de números leva cerca de um segundo em Python e cerca
de dez milissegundos em C. Isso soa fatal e não é, por um motivo que vale entender agora:

> O Python que você vai escrever para dados passa quase todo o tempo dentro de bibliotecas que não
> são escritas em Python. `pandas` e `numpy` são C por baixo. O seu código é a camada fina que diz o
> que fazer; a aritmética acontece em outro lugar, rápido.

A aula 20 é onde isso fica preciso. Por ora: Python é lenta para aritmética e quase nunca é ela que
deixa o seu programa lento.

**E os erros chegam tarde.** Um nome escrito errado num ramo que ninguém tomou é um problema que se
encontra em produção em vez de na compilação. É esse o buraco de que as aulas 14 a 16 tratam —
anotações e um verificador que as lê, que é o aviso prévio de um compilador aparafusado de volta por
escolha.

## Onde ela roda de fato

O mesmo arquivo roda em Linux, macOS e Windows, porque o que muda é o interpretador e não o arquivo.
É uma promessa real e tem uma borda famosa — caminhos, que a aula 9 resolve com `pathlib`
exatamente por isso.
