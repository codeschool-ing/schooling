---
title: Leia de baixo para cima
version: 1
---

Esta é a seção mais útil da aula e possivelmente da primeira metade do curso.

Quando o Python não consegue fazer o que uma linha diz, ele para e imprime um **traceback**. Parece
um muro. São quatro fatos numa ordem fixa, e a ordem está de cabeça para baixo de propósito.

```
Traceback (most recent call last):
  File "/home/ada/greet.py", line 2, in <module>
    greeting = "Hello, " + nmae
                           ^^^^
NameError: name 'nmae' is not defined
```

## A última linha primeiro: o que aconteceu

`NameError: name 'nmae' is not defined`

Duas metades. **`NameError`** é o tipo da falha — uma de talvez uma dúzia que você vai encontrar no
primeiro mês, e a aula 8 nomeia todas. **O texto depois dos dois pontos** é a queixa específica,
escrita para uma pessoa.

## A penúltima: onde

`File "/home/ada/greet.py", line 2` — o arquivo e a linha em que o interpretador estava. Depois a
própria linha, devolvida entre aspas, com `^^^^` embaixo da parte que ele não conseguiu resolver.

Esse circunflexo faz trabalho de verdade. Numa linha longa com quatro chamadas de função, ele diz
qual delas.

## O topo: como chegou ali

`Traceback (most recent call last)` quer dizer o que está escrito: a lista acima do erro é a cadeia
de chamadas que levou até aqui, **da mais antiga para a mais recente**. Num programa de um arquivo é
uma linha só e dá para ignorar. Quando o seu programa tem funções chamando funções, é essa parte que
conta o caminho.

## Por que de cabeça para baixo

Porque a última linha é a resposta, e a resposta deve estar perto de onde o seu olho já está — no pé
do terminal, onde você acabou de apertar Enter.

## Os quatro desta semana

| | quer dizer |
|---|---|
| `NameError` | você usou uma palavra para a qual o Python não tem significado — quase sempre um erro de digitação, às vezes um import faltando |
| `SyntaxError` | o arquivo não pôde ser lido de jeito nenhum; nada rodou |
| `TypeError` | a operação existe, mas não para estes tipos — `"2" + 2` |
| `IndentationError` | os espaços no começo de uma linha não se alinham |

**O `SyntaxError` é o diferente**, e vale saber por quê: os outros acontecem enquanto o seu programa
roda, então tudo acima da linha que falhou já aconteceu. Um `SyntaxError` acontece *antes* de
qualquer coisa rodar, porque o interpretador não conseguiu terminar de ler o arquivo. Se você vê um,
nenhuma parte do seu programa executou — nem o `print` da linha 1.
