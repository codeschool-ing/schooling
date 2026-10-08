---
title: O `awk`, uma linguagem de programação que se escreve numa linha
version: 3
---

O `awk` lê uma linha, divide em campos, e roda o seu código nela. É esse o modelo inteiro, e é o que
faz do `awk` a ferramenta que faz o que o `cut`, o `grep` e uma calculadora teriam que fazer juntos.

```
ana@vm:~/work$ awk '{print $1}' logs/access.log | head -2
198.51.100.10
198.51.100.15
ana@vm:~/work$ awk '{print $9, $7}' logs/access.log | head -3
200 /
200 /
200 /
```

**O `$1` é o primeiro campo, o `$0` é a linha inteira, o `$NF` é o último.** Os campos são divididos
em sequências de espaço em branco por padrão — o que já é melhor que o `cut`, já que não precisa de
`tr -s` em texto com preenchimento.

E o segundo comando reordenou os campos, o que a seção 08 mostrou que o `cut` não consegue fazer.

## A forma de um programa

```localised
awk 'pattern { action }'
```

Qualquer uma das metades pode ser omitida:

| | |
|---|---|
| `{ print $1 }` | sem padrão: faça para toda linha |
| `$9 == 500` | sem ação: imprima a linha inteira quando for verdade |
| `/api/ { c++ }` | as duas |

```
ana@vm:~/work$ awk '$9 == 500 {print $7}' logs/access.log | sort | uniq -c
      6 /
      4 /api/orders
      1 /api/orders/new
      1 /favicon.ico
      8 /health
      1 /index.html
      2 /static/app.css
      1 /static/app.js
ana@vm:~/work$ awk '$9 >= 400' logs/access.log | wc -l
78
```

**O `$9 >= 400` é a coisa que o `grep` não consegue fazer**, porque é aritmética num campo em vez de
correspondência de texto. Aqui está a diferença, medida:

```
ana@vm:~/work$ awk '$9 >= 400 && $9 < 500' logs/access.log | wc -l
54
ana@vm:~/work$ grep -c ' 4[0-9][0-9] ' logs/access.log
80
ana@vm:~/work$ grep ' 4[0-9][0-9] ' logs/access.log | awk '$9 < 400 || $9 >= 500' | head -2
10.0.1.28 - - [14/Sep/2026:06:14:58 +0000] "GET /static/app.css HTTP/1.1" 500 419 "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)" 145
10.0.1.10 - - [14/Sep/2026:06:32:19 +0000] "GET /static/app.js HTTP/1.1" 200 410 "python-requests/2.32.3" 190
```

**Cinquenta e quatro contra oitenta, e os vinte e seis extras nem são respostas 4xx.** Os dois
mostrados são um `500` e um `200` cujos *tamanhos em bytes* eram 419 e 410, que o padrão casou
porque ele não faz ideia de qual número é o status. O
`awk` foi perguntado sobre o campo nove e o `grep` foi perguntado sobre uma forma.

## As variáveis embutidas

| | |
|---|---|
| `NR` | o número do registro — a linha em que você está |
| `NF` | o **número de campos** nesta linha |
| `FS` | o separador de campo de entrada. O `-F,` define |
| `OFS` | o separador de saída, usado pelo `print a, b` |

```
ana@vm:~/work$ awk 'END {print NR}' logs/access.log
1200
```

O `END` roda uma vez depois da última linha, e o `BEGIN` roda uma vez antes da primeira. **O
`END {print NR}` é o `wc -l`**, e o motivo de saber disso é que o `NR` também está disponível no
corpo: o `NR > 1` pula um cabeçalho, o `NR % 100 == 0` amostra a cada centésima linha.

## A conferência que vale rodar em qualquer arquivo novo

```
ana@vm:~/work$ awk '{print NF}' logs/access.log | sort -u
12
15
18
20
```

**Quatro contagens de campo diferentes, num arquivo em que toda linha parece ter a mesma forma.**
Isso não é corrupção: a string de user-agent está entre aspas e contém espaços, e o `awk` divide em
espaço em branco sem se importar com aspas.

Que é o aviso que esta seção precisa carregar. **O `$7` é o caminho em toda linha deste log** — o
`awk '{print $7}' | grep -cv '^/'` devolve `0` — porque a variação começa depois dele. O `$11` não é:

```
ana@vm:~/work$ awk '{print $11}' logs/access.log | sort | uniq -c | sort -rn
    553 "Mozilla/5.0
    287 "kube-probe/1.29"
    191 "curl/8.5.0"
    169 "python-requests/2.32.3"
```

Três daqueles são strings de user-agent inteiras e um é a **primeira palavra de uma mais longa**.
Qualquer campo a partir de um campo de texto livre é pouco confiável; o `$NF` continua confiável,
porque ele conta da outra ponta.

## Aritmética, que é por que as pessoas o pegam

```
ana@vm:~/work$ awk '{n++; bytes += $10} END {print n, bytes, bytes/n}' logs/access.log
1200 11880770 9900.64
```

Mil e duzentas requisições, uns doze megabytes, uma média de uns dez kilobytes cada. **Variáveis não
precisam de declaração e começam em zero**, que é o que torna comandos de uma linha tão curtos.

```
ana@vm:~/work$ awk -F, 'NR>1 {s+=$5} END {print s}' data/sales.csv
571083
```

A seção 08 fez isso com quatro processos e o `bc`.

## Arrays associativos, que é por que ele substitui o `sort | uniq -c`

```
ana@vm:~/work$ awk -F, 'NR>1 {rev[$1] += $5} END {for (r in rev) print r, rev[r]}' data/sales.csv | sort
east 130235
north 143924
south 125015
west 171909
```

**O `rev[$1] += $5` é um agrupar-por e uma soma**, numa expressão, numa passagem. Um array indexado
por uma string, criado no primeiro uso.

Esse é o padrão para guardar. Contar é a mesma coisa com `++`:

```
awk '{c[$7]++} END {for (p in c) print c[p], p}' logs/access.log | sort -rn | head
```

A seção 10 mostrou aquilo dando a mesma resposta que o `sort | uniq -c`, sem o sort.

**A ordem do `for (k in arr)` é indefinida**, que é por que os dois terminam em `| sort`.

## Formatação

```
ana@vm:~/work$ awk '$NF > 3000 {printf "%-22s %6s ms  %s\n", $1, $NF, $7}' logs/access.log | head -4
203.0.113.11             4885 ms  /api/reports
10.0.1.29                5560 ms  /api/reports
10.0.1.7                 4422 ms  /api/reports
10.0.1.29                4960 ms  /api/reports
```

O `printf` é o do C: `%s` string, `%d` inteiro, `%.2f` duas casas decimais, `%-22s` alinhado à
esquerda em 22 colunas. **O `printf` precisa do próprio `\n`**; o `print` acrescenta um.

```
ana@vm:~/work$ awk 'BEGIN {FS=","; OFS=" | "} NR<4 {print $2, $4}' data/sales.csv
rep | units
ana | 145
bruno | 275
```

Definir o `FS` e o `OFS` no `BEGIN` é a alternativa ao `-F`, e é o único jeito de definir o separador
de *saída*. Repare que o `print $2, $4` usa o `OFS` para a vírgula e o `print $2 $4` — sem vírgula —
concatena sem nada no meio.

## Padrões que são expressões regulares

```
ana@vm:~/work$ awk '/api/ {c++} END {print c " api requests"}' logs/access.log
285 api requests
```

O `/padrão/` casa com a linha inteira, o `$7 ~ /padrão/` com um campo, e o `!~` é "não casa". A
linguagem de padrões é a sintaxe estendida da seção 07.

## Quando parar

O `awk` tem funções, `getline`, múltiplos arquivos, `ARGV`, funções de string e redirecionamento de
saída. É uma linguagem de verdade e o manual tem cem páginas.

**A linha a traçar é esta**: quando o programa precisa de uma segunda condição e de uma terceira
variável, e você começou a contar aspas, ele virou um programa. Escreva num arquivo — que é a aula 9
— ou em python. Um `awk` de uma linha com doze partes é impressionante e ninguém nunca vai conseguir
mudá-lo com segurança.

O `awk` que vale ter nos dedos são cinco padrões:

```
awk '{print $3}'                             # a column
awk '$9 >= 400'                              # a numeric condition
awk -F, 'NR>1 {s+=$5} END {print s}'         # a sum
awk '{c[$7]++} END {for(k in c) print c[k], k}'   # a group-by count
awk '{print NF}' file | sort -u              # is this file the shape I think
```
