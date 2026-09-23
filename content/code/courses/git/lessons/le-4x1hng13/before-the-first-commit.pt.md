---
title: Antes do primeiro commit — instale o Git e diga a ele quem você é
version: 1
---

A aula 2 começa a fazer commits, e uma máquina nova não está pronta para um. Esta seção a deixa
pronta. São quatro comandos, e cada um está aqui por causa de algo que o Git vai fazer com você se
você não os rodar.

## Ele está aí?

```
ana@vm:~$ git --version
git version 2.43.0
```

Qualquer versão a partir da 2.23 tem todos os comandos que este curso usa; foi nessa versão, de
2019, que `git switch` e `git restore` chegaram. Se o shell responder `command not found`, instale.
No Debian e no Ubuntu é `sudo apt install git`. No macOS, digitar `git` num terminal oferece instalar
as ferramentas de desenvolvedor da Apple, que o incluem. No Windows, o instalador de git-scm.com traz
o Git e um terminal chamado Git Bash, e todo comando deste curso funciona nesse terminal.

## O que o Git diz na primeira vez

Aqui está uma conta nova criando um repositório e tentando salvar uma primeira versão, antes de
alguém configurar qualquer coisa:

```
ana@vm:~$ mkdir first && cd first
ana@vm:~/first$ git init
hint: Using 'master' as the name for the initial branch. This default branch name
hint: is subject to change. To configure the initial branch name to use in all
hint: of your new repositories, which will suppress this warning, call:
hint: 
hint: 	git config --global init.defaultBranch <name>
hint: 
hint: Names commonly chosen instead of 'master' are 'main', 'trunk' and
hint: 'development'. The just-created branch can be renamed via this command:
hint: 
hint: 	git branch -m <name>
Initialized empty Git repository in /home/ana/first/.git/
ana@vm:~/first$ echo 'first line' > notes.txt
ana@vm:~/first$ git add notes.txt
ana@vm:~/first$ git commit -m "Start the notes"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@vm.(none)')
```

Duas reclamações, e **a segunda é uma recusa**: nenhum commit foi feito. Você viu o motivo nas duas
últimas seções. Todo commit registra um autor, e o Git não vai inventar um. Ele tentou — `ana@vm.(none)`
é o nome da conta e o nome da máquina colados — e decidiu, com razão, que aquilo não é um endereço.

**As duas mensagens dizem exatamente o que digitar.** Leia-as, porque as mensagens do Git costumam
ser boas assim, e o hábito de pulá-las sai caro depois.

## Dizendo a ele

```
ana@vm:~$ git config --global user.name "Ana Souza"
ana@vm:~$ git config --global user.email "ana@example.com"
ana@vm:~$ git config --global init.defaultBranch main
ana@vm:~$ git config --global core.editor nano
```

Nenhum deles imprime nada, que é como um comando diz que deu certo. **`--global` quer dizer *para a
minha conta, em todo repositório*.** Sem ele, a configuração vale para o repositório em que você está
e para nenhum outro — útil num repositório do trabalho que deve levar o seu endereço do trabalho.

**O nome e o endereço não são um login.** Não há senha e nada os verifica. Eles são copiados para
todo commit que você faz, e um commit é copiado para todo clone, então trate-os como públicos e
permanentes. Se você prefere não publicar o seu endereço pessoal, o GitHub e o GitLab dão, cada um,
um endereço de repasse privado para usar aqui, e ligam os commits à sua conta por ele.

## O que isso escreveu

Esses quatro comandos editaram um arquivo de texto pequeno na sua pasta pessoal, e vale lê-lo uma
vez para ele não ser um mistério depois:

```schooling-example
{"language": "ini", "file": ".gitconfig", "parts": [{"code": "[user]\n\tname = Ana Souza\n\temail = ana@example.com", "note": "Quem você é, copiado para cada commit que você fizer. Uma seção entre colchetes, depois as configurações dela, uma por linha. O tab é a indentação do próprio Git."}, {"code": "[init]\n\tdefaultBranch = main", "note": "O nome do primeiro branch em todo repositório novo — o que o hint pedia. `main` é como GitHub e GitLab chamam os deles hoje. Branches são a aula 5."}, {"code": "[core]\n\teditor = nano", "note": "O editor que o Git abre quando precisa que você escreva algo maior do que o `-m` permite. Sem essa configuração, ele é o que o sistema escolheu, muitas vezes o vim, que é difícil de sair na primeira vez. O nano mostra os atalhos dele no pé da tela."}]}
```

O Git lê esse arquivo toda vez que roda. Você pode editá-lo à mão, e a mudança vale a partir do
próximo comando. Pedir a lista ao Git dá as mesmas quatro configurações, uma por linha:

```
ana@vm:~$ git config --global --list
user.name=Ana Souza
user.email=ana@example.com
init.defaultbranch=main
core.editor=nano
```

O `defaultBranch` do arquivo volta como `defaultbranch`. Os nomes das configurações ignoram
maiúsculas e minúsculas, então as duas grafias são a mesma configuração, e o Git imprime a forma em
minúsculas.

É tudo de que a aula 2 precisa. Ela começa pelo commit que o Git acabou de recusar, e pelo que o
`git add` fez antes dele.
