---
title: O `sort`, e a opção que não é opcional
version: 1
---

O `sort` ordena linhas. A ordem padrão é **alfabética, pela linha inteira**, e a primeira coisa a
saber é quando isso está errado.

```
ana@vm:~/work$ cut -d, -f4 data/sales.csv | tail -n +2 | sort | head -4
109
113
122
123
ana@vm:~/work$ cut -d, -f4 data/sales.csv | tail -n +2 | sort -n | head -4
26
31
40
49
```

**Os mesmos números, duas respostas, e a primeira está errada.** Alfabeticamente o `109` vem antes
do `26`, porque o `1` vem antes do `2` — e é ordem alfabética correta, aplicada a algo que não é
texto.

**O `-n` é a opção que você vai esquecer e depois ter que aprender duas vezes.** Toda vez que a coisa
que você está ordenando é um número — uma contagem, um tamanho, uma duração, uma porta — ela precisa
do `-n`.

| | |
|---|---|
| `-n` | numérico |
| `-h` | numérico **humano**: entende `1K`, `2.5M`, `3G`. Para a saída do `du -h` |
| `-r` | invertido |
| `-u` | único: descarta linhas duplicadas pelo caminho |
| `-t` | o separador de campo |
| `-k` | qual campo, ou campos |

## Ordenando por um campo

```
ana@vm:~/work$ sort -t, -k5 -rn data/sales.csv | head -3
north,ana,Q2,387,43731
east,felipe,Q4,338,41574
south,carla,Q1,292,37084
```

O `-t,` define o separador, o `-k5` é o quinto campo, o `-rn` é numérico invertido. A maior receita
primeiro.

**O `-k` aceita uma faixa, e a faixa importa mais do que parece.** O `-k5` quer dizer "do campo 5 até
o fim da linha", não "campo 5". Para um campo só você quer `-k5,5`:

```
ana@vm:~/work$ sort -t, -k1,1 -k3,3 data/sales.csv | head -4
east,elena,Q1,31,3348
east,felipe,Q1,338,24336
east,elena,Q2,332,20584
east,felipe,Q2,109,12862
```

Região primeiro, e depois trimestre dentro da região. **Duas opções `-k` são duas chaves de
ordenação**, aplicadas em ordem, que é como se expressa "agrupe por isto, e ordene por aquilo".

E um modificador pode ir numa chave em vez de no comando inteiro: o `-k5,5nr` ordena aquele campo
numericamente ao contrário, deixando os outros em paz.

## O `-u` e o que ele não faz

```
ana@vm:~/work$ sort -u logs/app.log
app handled a request
app ready
app started
```

Trinta linhas entram, três saem. O `sort -u` é `sort | uniq` num processo só, e é a escolha certa
quando você só quer os valores distintos.

**Não é a escolha certa quando você quer contagens**, porque ele joga fora a informação de que o
`uniq -c` precisa. Isso é a seção 128.

## Locale, e por que o `sort` às vezes discorda de si mesmo

```
ana@vm:~/work$ printf "b\na\nB\nA\n" | sort
A
B
a
b
ana@vm:~/work$ printf "b\na\nB\nA\n" | LC_ALL=C sort
A
B
a
b
```

**Os dois concordam aqui, e nem sempre concordam.** O locale desta máquina é `C.UTF-8`, que ordena
por valor de byte, então o `LC_ALL=C` não muda nada. Numa máquina configurada como `en_US.UTF-8` o
primeiro comando dá `a A b B` — sem diferenciar caixa, letra por letra — e o segundo continua dando
`A B a b`.

Isso importa em exatamente uma situação e ela é ruim: **um script que compara saída ordenada entre
duas máquinas.** O `comm` e o `join` da seção 133 exigem que as entradas estejam ordenadas *do mesmo
jeito*, e duas máquinas com locales diferentes produzem ordens diferentes dos mesmos dados.

O conserto é ser explícito. **`LC_ALL=C sort` num script** torna a ordem determinística, e também é
mais rápido, porque comparar bytes é mais barato que colação.

## Arquivos grandes

O `sort` guarda o que precisa na memória e despeja o resto em arquivos temporários, então ele
funciona em entradas maiores que a RAM. Duas opções para quando isso importa:

```
sort -S 2G big.log            # use this much memory before spilling
sort -T /var/tmp big.log      # put the temporary files here
```

**O `-T` é o que te salva**, numa máquina em que o `/tmp` é pequeno e o arquivo não. O erro quando
ele acaba é `No space left on device` apontando para um diretório que você não escolheu.

E o `sort --parallel=4` usa vários núcleos, o que num arquivo grande é uma diferença real.

## Os dois hábitos

**Reduza antes de ordenar.** `grep` e `cut` primeiro: ordenar mil e duzentos campos de quatro
caracteres é mais barato que ordenar mil e duzentas linhas de cento e cinquenta, e num log grande a
proporção é a mesma mas os números são minutos.

**E confira o `-n` toda santa vez.** A falha é silenciosa, a saída parece ordenada, e `109` antes de
`26` é fácil de não ver numa lista de duzentos.
