---
title: O `cut`, e onde ele deixa de bastar
version: 1
---

O `cut` fica com parte de cada linha e joga o resto fora. Ele tem exatamente três modos e você vai
usar dois deles.

```
ana@vm:~/work$ head -2 data/sales.csv
region,rep,quarter,units,revenue
north,ana,Q1,171,8721
ana@vm:~/work$ cut -d, -f2,5 data/sales.csv | head -4
rep,revenue
ana,8721
bruno,4116
carla,37084
```

| | |
|---|---|
| `-d` | o delimitador. **Um único caractere**, e o padrão é TAB |
| `-f` | quais campos: `3`, `2,5`, `2-4`, `2-` |
| `-c` | posições de caractere em vez de campos |

O `-f2-` é "do segundo até o fim", que é a forma que você quer quando não sabe quantos campos há:

```
ana@vm:~/work$ cut -d, -f2- data/sales.csv | head -3
rep,quarter,units,revenue
ana,Q1,171,8721
bruno,Q1,49,4116
```

## O `-d` é um caractere, não uma string

**Não existe `-d ", "`.** O `cut` aceita um único caractere e essa é uma limitação real: um arquivo
separado por `, ` ou por sequências de espaços não pode ser cortado diretamente.

O conserto de sempre é o `tr -s` da seção 130, que comprime sequências de um caractere em um só:

```
ana@vm:~/work$ head -2 logs/access.log | tr -s " " | cut -d" " -f1,6,7
10.0.1.6 "GET /static/app.js
10.0.1.11 "GET /
```

O outro conserto é usar o `awk`, que divide em sequências de espaço em branco por padrão e é a seção
132.

## No log

```
ana@vm:~/work$ cut -d" " -f1,7,9 logs/access.log | head -3
10.0.1.6 /static/app.js 200
10.0.1.11 / 200
10.0.1.25 /index.html 404
```

Endereço, caminho, status, de linhas de cento e cinquenta caracteres. **Este é o uso de cavalo de
batalha**: estreite para as colunas de que a pergunta trata, e deixe o `sort` e o `uniq` contarem.

## O `-c`, para texto de largura fixa

```
ana@vm:~/work$ cut -c1-15 logs/access.log | head -3
10.0.1.6 - - [1
10.0.1.11 - - [
10.0.1.25 - - [
```

**Aquela saída é inútil e é esse o ponto.** Posições de caractere só funcionam quando as colunas de
fato se alinham — saída do `ls -l`, alguns relatórios antigos, exportações de largura fixa de um
mainframe. Em qualquer coisa em que a largura dos campos varia, o `-c` corta no meio das coisas.

Onde funciona, funciona bem: `cut -c1-10` num log cujas linhas começam todas com uma data de formato
fixo é o jeito mais rápido de tirar a data.

## Onde o `cut` para

Três limites, e cada um é motivo para ir para o `awk`:

**Ele não consegue reordenar:**

```
ana@vm:~/work$ cut -d, -f5,2 data/sales.csv | head -2
rep,revenue
ana,8721
ana@vm:~/work$ awk -F, 'NR<3 {print $5, $2}' data/sales.csv
revenue rep
8721 ana
```

Pedi o campo 5 e depois o 2 e o `cut` me deu 2 e depois 5. **O `cut` produz campos na ordem do
arquivo** e não há opção para isso; o `awk` os imprime na ordem em que você escreveu.

**Ele não lida com campos entre aspas:**

```
ana@vm:~/work$ printf "id,name\n1,\"Smith, John\"\n" | cut -d, -f2
name
"Smith
```

A vírgula dentro das aspas é uma vírgula para o `cut`, então o nome saiu cortado ao meio. **Nada
nesta aula interpreta CSV corretamente**; para CSV de verdade com aspas, use uma ferramenta que
conheça o formato — o `csvcut` do csvkit, o `mlr`, ou algumas linhas de python.

**Ele não lida com espaço em branco variável** sem um `tr -s` antes, como acima.

A regra prática: **`cut` para um delimitador limpo, `awk` para todo o resto.** O `cut` é mais curto
de digitar e mais rápido em arquivos muito grandes, que é por que ainda vale conhecê-lo.

## O problema do cabeçalho

Todo exemplo acima imprimiu a linha de cabeçalho junto com os dados, porque o `cut` não faz ideia do
que é um cabeçalho. Dois jeitos de descartá-lo:

```
tail -n +2 data/sales.csv | cut -d, -f5      # skip line 1, then cut
awk -F, 'NR>1 {print $5}' data/sales.csv     # awk knows which line it is on
```

**O `tail -n +2` é a opção da seção 123** e é a de pegar com o `cut`. E tendo descartado o cabeçalho,
dá para acrescentar a aritmética:

```
ana@vm:~/work$ cut -d, -f5 data/sales.csv | tail -n +2 | paste -sd+ | bc
573278
```

Quatro programas para somar uma coluna: pegue o campo, descarte o cabeçalho, junte as linhas com
sinais de `+`, e entregue a soma resultante a uma calculadora. Funciona, é genuinamente como as
pessoas fazem isso, e a seção 132 faz a mesma coisa em um:

```
ana@vm:~/work$ awk -F, 'NR>1 {s+=$5} END {print s}' data/sales.csv
573278
```

Mesmo número, um processo em vez de quatro, e nenhum `bc` para instalar.
