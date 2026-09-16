---
title: O pipe, e a ideia de que o resto desta aula é feito
version: 1
---

Um pipe conecta a saída padrão de um programa à entrada padrão do seguinte. É esse o mecanismo
inteiro, e é o motivo de o Unix ter centenas de comandos pequenos em vez de uma dúzia de grandes.

```
ana@vm:~/work$ cut -d" " -f9 logs/access.log | sort | uniq -c | sort -rn
   1033 200
     70 201
     28 404
     21 500
     18 302
     16 304
      9 401
      5 403
```

**Quatro programas, nenhum dos quais sabe nada sobre servidores web**, e a resposta é todo tipo de
resposta que este servidor deu e quantas de cada. Leia da direita para a esquerda como uma série de
decisões:

| | |
|---|---|
| `cut -d" " -f9` | fique com o nono campo separado por espaço: o código de status |
| `sort` | ponha códigos iguais um ao lado do outro |
| `uniq -c` | agrupe sequências, e conte |
| `sort -rn` | ordene por aquela contagem, maior primeiro |

Ninguém escreveu uma ferramenta para esta pergunta. Ela foi montada em uns quinze segundos com
ferramentas mais velhas que a web.

## Os quatro processos rodam ao mesmo tempo

`a | b` não quer dizer "rode o `a`, depois rode o `b`". O shell inicia **os dois**, e o `b` lê o que
o `a` tiver produzido até então.

Isso vale saber por dois motivos práticos.

**Um pipeline pode terminar antes do primeiro comando.** O `head` é o exemplo — o `SIGPIPE` da aula
6 seção 08, em que `yes | head -2` mata o `yes` em vez de esperar por ele. Então `grep algo
enorme.log | head -5` volta assim que tiver cinco linhas, por maior que seja o arquivo.

**E a memória não é o limite.** O `sort` num arquivo de dez gigabytes de fato despeja em disco, mas
um pipeline que só filtra segura alguns kilobytes por vez, por mais que passe por ele. O pipeline
acima nunca teve mais do que um buffer daquele log na memória.

## O `$?` depois de um pipeline

```
false | true; echo $?          # 0 — the status of the LAST command
```

A aula 6 seção 14 cobriu isso e vale repetir aqui porque é em pipelines que isso morde: **o `$?` é o
código da última etapa**, então uma falha na frente fica invisível. O `PIPESTATUS` tem todos eles, e
o `set -o pipefail` muda a regra.

## Reduza primeiro

O pipeline do topo poderia igualmente ser escrito:

```
sort logs/access.log | cut -d" " -f9 | uniq -c | sort -rn
```

Mesma resposta, e ele ordena mil e duzentas linhas inteiras em vez de mil e duzentos campos curtos.
Neste arquivo ninguém notaria. Num log de dez milhões de linhas é a diferença entre segundos e
minutos.

**O hábito é: jogue fora o que você não precisa o mais cedo possível.** `grep` antes do `cut`, `cut`
antes do `sort`, e `head` por último se você só quer os primeiros.

A única exceção é o `grep`: pô-lo primeiro quer dizer que ele varre linhas inteiras em vez de um
campo, e essa ainda é quase sempre a troca certa, porque ele remove linhas por inteiro.

## O que um pipe não é

**Ele não é um arquivo.** Nada consegue voltar atrás nele, que é por que o `tail` num pipe precisa
ler tudo, e por que alguns programas se recusam a trabalhar dentro de um.

**Ele carrega bytes, não registros.** Toda ferramenta desta aula inventa a própria ideia de linha e
de campo a partir do mesmo fluxo de bytes, que é por que elas se compõem — e também por que um nome
de arquivo com espaço quebra um pipeline que assumiu que espaço separa coisas. A seção 16 é essa
falha, com o conserto.

**E ele carrega só a saída padrão.** Os erros passam por fora, que é o `2>&1 |` da seção 03.

## O conjunto pequeno que faz quase tudo

O resto desta aula são estes, e vale vê-los como uma lista antes de encontrá-los um por um:

| | |
|---|---|
| `grep` | fique com as linhas que casam |
| `cut` | fique com algumas colunas |
| `sort` | ordene |
| `uniq` | agrupe e conte duplicatas adjacentes |
| `wc` | conte linhas, palavras, bytes |
| `tr` | substitua ou apague caracteres |
| `sed` | substitua padrões, apague linhas, imprima faixas |
| `awk` | tudo acima, com aritmética e condições |
| `head`, `tail` | os primeiros ou os últimos |
| `xargs` | transforme linhas em argumentos de outro comando |

**Nove desses dez leem a entrada padrão, escrevem na saída padrão e não fazem mais nada.** O `xargs`
é a exceção, e existe justamente porque alguns comandos aceitam argumentos em vez de entrada.
