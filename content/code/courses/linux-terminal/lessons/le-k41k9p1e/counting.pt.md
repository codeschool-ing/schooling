---
title: O `wc`, e o que "uma linha" quer dizer
version: 1
---

O `wc` conta. Três números, numa ordem fixa:

```
ana@vm:~/work$ wc logs/access.log
  1200  16995 148233 logs/access.log
```

**Linhas, palavras, bytes.** E com opções, um de cada vez:

| | |
|---|---|
| `-l` | linhas |
| `-w` | palavras — sequências de não-espaço |
| `-c` | **bytes** |
| `-m` | **caracteres**, que difere do `-c` em qualquer coisa não-ASCII |
| `-L` | o comprimento da linha mais longa |

```
ana@vm:~/work$ wc -l logs/*.log
  1200 logs/access.log
    30 logs/app.log
     0 logs/empty.log
     1 logs/error.log
  1231 total
```

Vários arquivos te dão um `total`, o que é conveniente e também é uma linha que você tem que lembrar
de descartar se for passar isso adiante.

## O `wc -l` conta quebras de linha

Este é o ponto inteiro da seção, e explica um erro de um que as pessoas cometem uma vez:

```
ana@vm:~/work$ printf "no newline at the end" > frag.txt; wc -l frag.txt; grep -c . frag.txt
0 frag.txt
1
```

**Um arquivo, uma linha de texto, e duas respostas: zero e um.**

O `wc -l` conta **caracteres de quebra de linha**, e aquele arquivo não tem nenhum. O `grep -c .`
conta linhas que contêm pelo menos um caractere, e acha uma.

Nenhum dos dois está errado. Eles respondem perguntas diferentes, e a diferença só aparece num
arquivo cuja última linha não tem quebra — o que é comum em arquivos escritos por programas, e em
qualquer coisa que saiu de um editor do Windows ou de um copiar e colar.

**Então: o `wc -l` está certo para arquivos que terminam direito, e o `grep -c ''` está certo quando
você não tem certeza.** Num arquivo bem formado eles concordam:

```
ana@vm:~/work$ grep -c . logs/app.log; wc -l < logs/app.log
30
30
```

## O `-c` contra o `-m`

O `-c` é bytes e o `-m` é caracteres, e em texto UTF-8 eles diferem sempre que algo não é ASCII. Um
arquivo de texto em português com acentos vai ter mais bytes do que caracteres, porque o `ã` são dois
bytes.

**Use o `-c` quando você se importa com disco ou tamanho de transferência** e o `-m` quando você se
importa com quanto texto há. E repare que o `head -c` da seção 05 também é bytes, que é por que
cortar um arquivo UTF-8 num byte arbitrário pode partir um caractere ao meio.

## Contando coisas que não são linhas

A maior parte das perguntas de contagem não é "quantas linhas neste arquivo", é "quantos *destes*", e
a forma é sempre a mesma:

```
grep -c " 500 " logs/access.log              # lines matching
grep -o "GET" logs/access.log | wc -l        # occurrences, not lines
cut -d" " -f1 logs/access.log | sort -u | wc -l   # distinct values
ls -1 | wc -l                                # files in a directory
```

**A terceira é o padrão para guardar**: o `sort -u | wc -l` é "quantos diferentes", e é uma pergunta
diferente de "quantos". Neste log há mil e duzentas requisições e bem menos endereços.

O `ls -1 | wc -l` tem a ressalva que a aula 3 deu: ele perde arquivos ocultos, e um nome de arquivo
com quebra de linha seria contado duas vezes. O `find . -maxdepth 1 -type f | wc -l` é a versão
cuidadosa, e o `ls -1A | wc -l` inclui os ocultos.

## O `wc` na entrada padrão, e o nome do arquivo

```
wc -l logs/app.log       # prints "30 logs/app.log"
wc -l < logs/app.log     # prints "30"
```

A seção 02 mostrou isso. Num script, **a segunda forma é a que você quer**, porque a saída é um
número e não um número mais um nome que você depois tem que cortar.

O `$(wc -l < arquivo)` é a expressão idiomática, e é por isso que o redirecionamento vale o caractere
a mais.
