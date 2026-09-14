---
title: Como responder às suas próprias perguntas
version: 1
---

Este curso cobre 223 seções e não vai cobrir tudo. **A habilidade que sobrevive a ele é saber
perguntar à máquina**, porque a máquina veio com a documentação dela e responde mais rápido que um
buscador.

Quatro formas de perguntar, na ordem em que você deve tentar.

## 1 · `--help`, para o formato de um comando

```
ana@vm:~$ ls --help | head -8
Usage: ls [OPTION]... [FILE]...
List information about the FILEs (the current directory by default).
Sort entries alphabetically if none of -cftuvSUX nor --sort is specified.

Mandatory arguments to long options are mandatory for short options too.
  -a, --all                  do not ignore entries starting with .
  -A, --almost-all           do not list implied . and ..
      --author               with -l, print the author of each file
```

Leia a primeira linha como a seção 07 te ensinou: o comando, depois `[OPTION]...`, depois
`[FILE]...`. Colchetes querem dizer opcional e `...` quer dizer repetível, e essa é a gramática
inteira de uma linha de uso.

O `--help` é a resposta mais rápida e quase sempre basta. Ele é impresso pelo próprio programa,
então nunca está desatualizado, e é curto. Mande para o `head` quando não for.

## 2 · `man`, para a conta completa

`man ls` abre a página de manual: cada opção, os status de saída, os padrões que ele segue, e os
comandos relacionados no fim. É um paginador — **`q` sai**, as setas rolam, `/` busca. Ninguém
conta para iniciante que `q` sai, e essa é a forma mais comum de se sentir preso num terminal.

O manual tem seções numeradas, e os números importam exatamente uma vez: `man 5 passwd` é o formato
do arquivo, `man 1 passwd` é o comando. Quando uma página parece ser sobre a coisa errada, é por
isso.

**E ele pode não estar instalado.** Num contêiner ou numa imagem de nuvem minimizada:

```
ana@vm:~$ man ls
This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, including manpages, you can run the 'unminimize'
command. You will still need to ensure the 'man-db' package is installed.
```

Nada está quebrado. A imagem foi construída pequena de propósito — a seção 04 avisou que um
contêiner novo vem sem ferramentas que você espera — e a mensagem diz exatamente como trazê-las de
volta. Esse é o estado comum de um contêiner, então o `--help` é o que sempre funciona.

## 3 · `type` e `help`, quando o `man` não tem nada

Alguns comandos não têm página de manual porque não são programas:

```
ana@vm:~$ type cd
cd is a shell builtin
```

O `cd` faz parte do bash. Não existe um `/bin/cd` para documentar, e é por isso que `man cd`
decepciona. Para os embutidos, o bash documenta a si mesmo:

```
ana@vm:~$ help cd | head -3
cd: cd [-L|[-P [-e]] [-@]] [dir]
    Change the shell working directory.
```

**`type` antes de qualquer coisa** é um bom hábito em geral: ele diz se um nome é um programa, um
embutido, um apelido que alguém criou, ou uma função. Quando um comando se comporta diferente do
que você leu, o `type` costuma ser a explicação.

## 4 · `apropos`, quando você não sabe o nome

O `apropos` busca nas descrições do manual, então ele responde "qual é o comando para…" em vez de
"o que este comando faz". `apropos "list directory"` acha o `ls`. Ele precisa das páginas de manual
instaladas, então numa imagem minimizada não acha nada, e a causa é a mesma de antes.

## E o `tldr`, que não vem instalado e vale instalar

O `tldr` é um projeto comunitário: os mesmos comandos, documentados como **cinco exemplos do que as
pessoas realmente digitam** em vez de cada opção. `tldr tar` é a resposta para a encantação de três
flags de que a aula 3 reclama.

Ele não vem com o sistema. `sudo apt install tldr` — e é a única coisa desta seção que precisa ser
buscada em vez de encontrada.

## Qual buscar

| a pergunta | pergunte com |
|---|---|
| quais são as opções deste comando? | `--help` |
| o que esta opção quer dizer, exatamente? | `man` |
| por que este comando está estranho? | `type` |
| qual é o comando para…? | `apropos` |
| me mostre o que as pessoas digitam | `tldr` |

E leia o erro primeiro. A seção 17 é a próxima porque, na prática, a resposta costuma estar na
linha que você já tem, e não num manual.
