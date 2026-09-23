---
title: O formato de um comando
version: 2
---

Todo comando que você vai digitar no resto deste curso tem as mesmas três partes, na mesma ordem:

```localised
comando   [opções]   [argumentos]
```

**O comando** é o que executar. **As opções** mudam como ele executa. **Os argumentos** são sobre o
que ele executa. Aprenda esse formato uma vez e mil comandos desconhecidos passam a ser adivinháveis
em vez de mágicos.

```
ana@vm:~/demo$ ls -l readme.txt
```

`ls` é o comando, `-l` é uma opção, `readme.txt` é o argumento.

## Opções vêm em duas grafias

```
$ ls
-strange
folder
readme.txt
with space.txt
```

Puro, sem nada acrescentado, o `ls` te dá nomes. Acrescente uma opção e o mesmo comando responde a
mesma pergunta com muito mais detalhe:

```
$ ls -l
total 16
-rw-r--r-- 1 ana ana    2 Sep 14 14:45 -strange
drwxr-xr-x 2 ana ana 4096 Sep 14 14:45 folder
-rw-r--r-- 1 ana ana   46 Sep 14 14:45 readme.txt
-rw-r--r-- 1 ana ana    4 Sep 14 14:45 with space.txt
```

**O comando não mudou. O que mudou foi o quanto da resposta ele mostrou.**

| grafia | parece | observações |
|---|---|---|
| **curta** | `-l`, `-a`, `-r` | uma letra, um hífen |
| **longa** | `--all`, `--recursive` | uma palavra, dois hifens; legível, e é o que você quer num script |
| **combinada** | `-la` é `-l` mais `-a` | só opções curtas, e a ordem entre elas raramente importa |

Combinar é comum e você vai ver o tempo todo:

```
$ ls -la
total 24
-rw-r--r-- 1 ana ana    2 Sep 14 14:45 -strange
drwxr-xr-x 3 ana ana 4096 Sep 14 14:45 .
drwxr-x--- 4 ana ana 4096 Sep 14 14:45 ..
-rw-r--r-- 1 ana ana    0 Sep 14 14:45 .hidden
drwxr-xr-x 2 ana ana 4096 Sep 14 14:45 folder
-rw-r--r-- 1 ana ana   46 Sep 14 14:45 readme.txt
-rw-r--r-- 1 ana ana    4 Sep 14 14:45 with space.txt
```

O `-a` acrescentou `.hidden`, `.` e `..` — três entradas que a listagem simples deixou de fora. A
seção 11 explica o ponto que esconde um arquivo; as seções 02 e 12 da aula 3 explicam as outras
duas.

**Nem toda opção curta tem uma gêmea longa, e nem toda longa tem uma curta.** O `--help` em geral
não tem forma curta que valha a pena. Isso é um fato sobre cada programa, e é para isso que serve o
`man` — seção 16.

## Algumas opções levam um valor próprio

```
$ head -n 2 readme.txt
first line
second line
$ head --lines=2 readme.txt
first line
second line
```

O `2` pertence à opção, não ao comando: ele diz *quantas* linhas. A forma curta normalmente leva o
valor depois de um espaço, a longa depois de um `=`, e muitos programas aceitam as duas grafias das
duas. Mesmo resultado, duas vezes — e num script, prefira `--lines=2`, porque daqui a seis meses
`-n 2` é um enigma e `--lines=2` é uma frase.

## Onde o formato morde

### Um espaço é separador, e ele significa algo

O shell quebra a sua linha nos espaços antes de o comando ver qualquer coisa. Então um nome de
arquivo com espaço chega como dois argumentos:

```
$ ls with space.txt
ls: cannot access 'with': No such file or directory
ls: cannot access 'space.txt': No such file or directory
```

Dois erros, porque o `ls` recebeu dois nomes e nenhum dos dois existe. Coloque aspas e vira um
argumento de novo:

```
$ ls 'with space.txt'
with space.txt
```

**Esse é o erro de iniciante mais comum do shell**, e no fundo ele não é sobre nomes de arquivo — é
sobre quem quebra a linha. A seção `quoting` da aula 9 é o tratamento completo; a regra para levar
até lá é *se tem espaço, ponha aspas em volta.*

### Um hífen na frente faz um argumento parecer uma opção

```
$ ls -strange
ls: invalid option -- 'e'
Try 'ls --help' for more information.
```

Existe um arquivo chamado `-strange` naquele diretório, e o `ls` nunca o considerou. Tudo que
começa com `-` é lido como opção, então ele pegou as letras uma a uma e parou logo na primeira,
o `e`, que não é opção nenhuma do `ls`. É por isso que a reclamação nomeia uma letra, e não o
nome do arquivo.

A correção é uma convenção que quase todo comando respeita — **`--` significa "acabaram as opções,
tudo depois disto é argumento"**:

```
$ ls -- -strange
-strange
```

Você vai encontrar isso na primeira vez que alguém te entregar um arquivo cujo nome começa com
hífen, e sem isso o arquivo é praticamente intocável.

### Leia o erro, e ele diz qual parte estava errada

Três falhas nesta seção e cada uma nomeia o próprio tipo:

| mensagem | o que quer dizer |
|---|---|
| `bash: celar: command not found` | o **comando** está errado — o shell não achou programa com esse nome |
| `ls: invalid option -- 'e'` | a **opção** está errada — o programa rodou, e recusou a flag |
| `ls: cannot access 'com'` | o **argumento** está errado — o programa rodou, aceitou a flag, e não achou a coisa |

Que é a mesma regra da seção 03, um nível mais fino: a mensagem diz em qual das três partes olhar.
Isso é a maior parte do trabalho de consertar.

## Ordem, e o que é flexível

Opções antes dos argumentos é a convenção e é sempre seguro. A maioria das ferramentas GNU no Linux
também aceita `ls readme.txt -l`, e as ferramentas BSD num Mac frequentemente não — então escreva do
jeito convencional e funciona em todo lugar.

Mais duas coisas que vale saber agora:

- **Maiúscula importa.** `-r` e `-R` costumam ser duas opções diferentes. `ls` e `LS` são dois
  comandos diferentes, e só um deles existe.
- **Espaços a mais são inofensivos.** `ls   -l` é o mesmo que `ls -l`. O shell junta a sequência de
  espaços quando quebra a linha — que é o mesmo mecanismo que transformou `with space.txt` em dois
  argumentos há pouco.
