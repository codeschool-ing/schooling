---
title: Absoluto e relativo, e a barra que decide
version: 1
---

Um caminho é um endereço. Existem exatamente dois tipos, e **um caractere separa os dois**:

| | começa com | quer dizer | exemplo |
|---|---|---|---|
| **absoluto** | `/` | a partir da raiz da árvore | `/home/ana/work/src/main.c` |
| **relativo** | qualquer outra coisa | a partir de onde você está | `work/src/main.c` |

Essa é a regra inteira. Todo o resto desta seção é consequência dela.

## "Onde você está" é uma coisa concreta

Todo processo no Linux tem um **diretório de trabalho atual** — um diretório em que ele se
considera. Seu shell tem um, e ele muda quando você dá `cd`. Pergunte com `pwd`:

```
ana@vm:~$ pwd
/home/ana
ana@vm:~$ cd work
ana@vm:~/work$ pwd
/home/ana/work
ana@vm:~/work$ cd src
ana@vm:~/work/src$ pwd
/home/ana/work/src
```

O prompt está mostrando o mesmo fato, encurtado — a seção 06 desmontou isso. `pwd` é a pergunta
direta, e é nele que se confia quando alguém customizou o prompt até deixá-lo ilegível.

**Um caminho relativo é resolvido contra esse diretório**, pelo kernel, no momento em que o comando
roda. Então:

```
ana@vm:~$ cd /home/ana/work/notes
ana@vm:~/work/notes$ ls ../src
main.c  util.c  util.h
```

`../src` significou `/home/ana/work/src` *por causa de onde o shell estava*. Digitado em outro
lugar, significaria outro lugar, ou nada.

## O mesmo arquivo, de quatro jeitos

Estando em `/home/ana/work/notes`, cada um destes nomeia o mesmo arquivo:

| caminho | tipo | por que funciona |
|---|---|---|
| `/home/ana/work/src/main.c` | absoluto | da raiz, por extenso |
| `../src/main.c` | relativo | um acima, depois abaixo |
| `~/work/src/main.c` | absoluto, depois da expansão | `~` vira `/home/ana` antes de o comando rodar |
| `../../ana/work/src/main.c` | relativo | bobo, e correto |

O último está aí para marcar um ponto: **um caminho não precisa ser o trajeto mais curto, só um
trajeto válido.** Subir dois e descer três é exatamente tão correto quanto subir um — o kernel
percorre o que você entregar.

## Quando usar cada um

A pergunta não é de estilo. É: **o que acontece se esta linha rodar em outro lugar?**

**Use absoluto quando a resposta não pode depender de onde você está.** Scripts, tarefas do cron,
units do systemd, arquivos de configuração, qualquer coisa que outra pessoa vá rodar, qualquer
coisa que rode sozinha. Uma tarefa do cron começa num diretório que você não escolheu, e
`logs/app.log` dentro dela é um bug esperando uma noite ruim.

**Use relativo quando a resposta *deve* depender de onde você está.** Trabalhando na mão dentro de
um projeto, movendo uma árvore que precisa manter a forma interna, escrevendo um `Makefile` que
tem de funcionar a partir da raiz do projeto onde quer que alguém tenha clonado.

Há mais uma razão para preferir absoluto em tudo que fica escrito, e não é sobre correção: **um
caminho absoluto pode ser lido por quem não está ali.** `/var/log/nginx/` conta tudo a um colega.
`../../logs/` não conta nada, a menos que ele também esteja vendo o seu prompt.

## Onde isso morde

### O mesmo comando, dois significados

Este é o que custa uma tarde:

```
rm -r build
```

Digitado em `/home/ana/work`, remove o seu diretório de build. Digitado em `/`, tenta remover
`/build`. **Nada no comando diz qual dos dois** — a barra ausente quer dizer "aqui", e "aqui"
mudou. O conserto é um hábito: antes de qualquer coisa destrutiva com caminho relativo, `pwd`.

### Um caminho dentro de um arquivo não é resolvido onde o arquivo está

Um arquivo de configuração em `/etc/myapp/conf` que diz `logs/app.log` **não** quer dizer
`/etc/myapp/logs/app.log`. Quer dizer o que for o diretório de trabalho do programa quando ele
subir, que normalmente é `/`. Isso surpreende todo mundo uma vez, e a surpresa é sempre a mesma: o
arquivo apareceu, só que não onde alguém olhou.

**Em arquivo de configuração, escreva o caminho por extenso.** Sempre.

### `./` na frente de um comando não é enfeite

```
ana@vm:~/work$ ./ledger data/report.csv
```

Rodar um programa do diretório atual exige `./` na frente. Isso não é sobre caminhos serem
relativos — é que o shell só procura no `$PATH` por um nome *pelado*, e `.` não está no `$PATH`.
Acrescentar `./` transforma o nome pelado num caminho, e um caminho não é procurado. A seção sobre
`$PATH` na aula 9 é a história completa; o hábito a construir agora é que `./alguma-coisa` quer
dizer *esta aqui, bem aqui*.

### O Windows diz a mesma coisa de outro jeito

| | Linux | Windows |
|---|---|---|
| separador | `/` | `\` |
| absoluto | `/home/ana/notes.txt` | `C:\Users\ana\notes.txt` |
| relativo | `notes.txt`, `../notes.txt` | `notes.txt`, `..\notes.txt` |
| uma raiz só? | sim, sempre `/` | uma por letra de unidade |

A ideia é idêntica: com a raiz na frente, do topo; sem ela, daqui. O que muda é que no Windows um
caminho absoluto precisa dizer também *qual árvore* — a letra da unidade — e no Linux só existe uma
árvore para estar no topo.
