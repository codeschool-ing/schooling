---
title: Lendo uma listagem longa, campo por campo
version: 1
---

Esta é a linha mais densa do curso, e você vai olhar para ela pelo resto da carreira.

```
ana@vm:~/work$ ls -l logs
total 12
-rw-r--r-- 1 ana ana 440 Mar 26  2025 app.log
-rw-r--r-- 1 ana ana   8 Mar 19  2025 app.log.1
-rw-r--r-- 1 ana ana   0 Mar 26  2025 empty.log
-rw-r--r-- 1 ana ana  31 Mar 26  2025 error.log
```

Pegue uma linha e desmonte.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma única linha de saída do ls -l, dividida em oito campos rotulados: um caractere de tipo, nove caracteres de permissão, a contagem de links, o dono, o grupo, o tamanho em bytes, a hora de modificação e o nome.\"><rect x=\"20\" y=\"18\" width=\"680\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--amber)\">-</text><text x=\"148.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--phosphor)\">rw-r--r--</text><text x=\"226.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">1</text><text x=\"272.4\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">ana</text><text x=\"328.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper-dim)\">ana</text><text x=\"385.2\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">440</text><text x=\"490.2\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper-dim)\">Mar 26  2025</text><text x=\"616.8\" y=\"41\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"18\" fill=\"var(--paper)\">app.log</text><path d=\"M70.8 72 L70.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"70.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">tipo</text><path d=\"M148.8 72 L148.8 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"148.8\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">permissões</text><path d=\"M226.8 72 L226.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"226.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">links</text><path d=\"M272.4 72 L272.4 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"272.4\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">dono</text><path d=\"M328.8 72 L328.8 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"328.8\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">grupo</text><path d=\"M385.2 72 L385.2 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"385.2\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">tamanho</text><path d=\"M490.2 72 L490.2 94\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"490.2\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">modificado</text><path d=\"M616.8 72 L616.8 150\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"616.8\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper-dim)\">nome</text><text x=\"360.0\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">oito campos, sempre nesta ordem, para cada entrada</text></svg>", "caption": "Uma linha de `ls -l`, desmontada. O primeiro caractere é o tipo da coisa; os nove seguintes são as permissões de que trata a aula 4."}
```

## Os oito campos

| # | campo | o que diz |
|---|---|---|
| 1 | `-` | **que tipo de coisa é esta** — um caractere |
| 2 | `rw-r--r--` | **permissões** — nove caracteres, três públicos de três |
| 3 | `1` | **contagem de links** — quantos nomes apontam para estes dados |
| 4 | `ana` | **dono** |
| 5 | `ana` | **grupo** |
| 6 | `440` | **tamanho em bytes** |
| 7 | `Mar 26  2025` | **quando o conteúdo mudou pela última vez** |
| 8 | `app.log` | **nome** |

## Campo 1: o caractere que todo mundo pula

Não é um traço de enfeite. É o tipo:

| | o que é | onde você encontra |
|---|---|---|
| `-` | um arquivo comum | em toda parte |
| `d` | um diretório | em toda parte |
| `l` | um link simbólico | `/bin`, `/lib`, e a seção 11 |
| `c` | um dispositivo de caractere | `/dev/null`, `/dev/tty` |
| `b` | um dispositivo de bloco | `/dev/vda` — um disco |
| `s` | um socket | `/run`, onde serviços escutam |
| `p` | um pipe nomeado | raramente, e você vai saber |

Então o jeito mais rápido de contar os diretórios de uma listagem é ler a primeira coluna de cima
a baixo:

```
ana@vm:~/work$ ls -l
total 28
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r-- 1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 build
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 src
```

Dois arquivos, cinco diretórios, e você não precisou abrir nada para saber.

## Campo 2: nove caracteres, em três grupos de três

`rw-r--r--` é `rw-`, `r--`, `r--`: **o que o dono pode fazer, o que o grupo pode fazer, o que todo
o resto pode fazer.** `r` ler, `w` escrever, `x` executar, `-` não pode.

Isso é a aula 4 inteira e merece a aula 4 inteira — a aritmética, as regras de diretório, os bits
que não estão nesses nove caracteres. O que você precisa aqui é só parar de ver ruído.
`-rw-r--r--` quer dizer *um arquivo que o dono pode alterar e todo mundo pode ler*, que é a cara de
um arquivo normal. `drwxr-xr-x` quer dizer *um diretório em que todos podem entrar e listar, e só o
dono pode acrescentar coisas*, que é a cara de um diretório normal.

## Campo 3: a contagem de links, e por que diretórios começam em 2

Para um arquivo é quase sempre `1`, e a seção 11 é sobre o dia em que não é.

Para um diretório **nunca** é 1, e o motivo são o `.` e o `..` da seção 04. Um diretório vazio tem
dois nomes apontando para ele: o próprio nome dentro do pai, e o `.` dentro de si mesmo. Acrescente
um subdiretório e o `..` desse subdiretório também aponta para ele, então a conta vira 3.

```
drwxr-xr-x 2 ana ana 4096 Mar 26  2025 logs
```

`2` quer dizer que `logs` não contém subdiretório nenhum. É uma informação real e gratuita sentada
numa coluna que ninguém lê.

## Campos 4 e 5: dono e grupo

Dois nomes, e eles respondem *qual* dos três grupos de caracteres de permissão se aplica a você. Se
você é a `ana`, os três primeiros. Se você está no grupo `ana` mas não é ela, os três do meio. Se
nenhum dos dois, os três últimos — e esse é o caso mais vezes do que as pessoas esperam.

**Só um dos três grupos se aplica**, e é o primeiro que casa. A aula 4 dedica uma seção a isso,
porque a intuição — "estou no grupo, então ganho os direitos do grupo por cima dos meus" — é errada
e custa uma tarde.

## Campo 6: o tamanho, e o que ele significa num diretório

Para um arquivo, o tamanho é em bytes. `-h` deixa legível:

```
ana@vm:~/work$ ls -lh
-rw-r--r-- 1 ana ana   66 Mar 22  2025 Makefile
drwxr-xr-x 2 ana ana 4.0K Mar 26  2025 build
```

Para um **diretório**, o número não é o tamanho do que está dentro. `4096` é o tamanho da própria
lista de nomes do diretório — e um diretório contendo quatrocentos gigabytes de vídeo vai continuar
dizendo `4096`. Esse é o assunto inteiro da seção 13; o que dá para consertar agora é a
expectativa.

## Campo 7: a data que muda de forma

Uma listagem, dois formatos de data:

```
ana@vm:~/work$ ls -la
total 40
drwxr-xr-x  7 ana ana 4096 Mar 26  2025 .
drwxr-x--- 10 ana ana 4096 Sep 14 21:58 ..
-rw-r--r--  1 ana ana   46 Mar 22  2025 .env
-rw-r--r--  1 ana ana   66 Mar 22  2025 Makefile
-rw-r--r--  1 ana ana  118 Mar 22  2025 README.md
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 build
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 data
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 logs
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 notes
drwxr-xr-x  2 ana ana 4096 Mar 26  2025 src
```

Todas as linhas dizem `Mar 2025`, menos o `..`, que diz `Sep 14 21:58`. **O `ls` imprime a hora
para qualquer coisa alterada nos últimos seis meses mais ou menos, e o ano para o que é mais
antigo.** Ele está tentando ser útil — em arquivos recentes é a hora que importa — e pega as
pessoas de surpresa quando elas ordenam uma listagem e veem dois formatos.

`ls -l --full-time` imprime tudo, sem ambiguidade, sempre. Vale saber quando você está comparando
o relógio de duas máquinas.

E repare *qual* hora é: **a última vez em que o conteúdo mudou.** Não quando o arquivo foi criado.
A seção 08 tira as outras duas marcas de tempo do `stat`.

## E a linha `total`

```
total 12
```

Não é contagem de arquivos e não é a soma dos tamanhos. É **o número de blocos de 1 KiB que o
disco deu a essas entradas** — o espaço realmente ocupado, que é por que quatro arquivos de 440, 8,
0 e 31 bytes somam 12. A seção 13 explica por que esses números não batem; por ora, `total` é sobre
disco, e a coluna de tamanho é sobre conteúdo.
