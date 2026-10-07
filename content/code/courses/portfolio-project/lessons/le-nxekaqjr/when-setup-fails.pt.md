---
title: Quando a preparação falha
version: 1
---

Preparar o ambiente é onde desiste a maioria de quem desiste de um curso, quase sempre por causa de um
erro que leva um minuto para resolver depois que alguém diz o que ele significa. Estes são os que
aparecem, e o que fazer.

**O terminal não conhece o comando.** Ao pedir `git --version`, a resposta é que `git` não foi
encontrado, ou *não é reconhecido*. Ou ele não está instalado, ou foi instalado com o terminal aberto e o
terminal não olhou de novo. Feche todos os terminais, abra um novo e pergunte outra vez; no Windows, use o
Git Bash em vez do antigo Prompt de Comando. No macOS, o primeiro `git` digitado pode abrir uma janela
oferecendo instalar as ferramentas de desenvolvedor, que é o mesmo `xcode-select --install`: aceite e
espere.

**O git recusa o primeiro commit.** É isto que ele diz quando a identidade nunca foi configurada:

```
ana@laptop:~$ mkdir project && cd project && git init -q && echo "# project" > README.md
ana@laptop:~/project$ git add README.md && git commit -m "Say what the project is for"
Author identity unknown

*** Please tell me who you are.

Run

  git config --global user.email "you@example.com"
  git config --global user.name "Your Name"

to set your account's default identity.
Omit --global to set the identity only in this repository.

fatal: unable to auto-detect email address (got 'ana@laptop.(none)')
```

A mensagem traz a própria correção. Digite as três linhas `git config --global` da seção anterior, com o
seu nome e o seu endereço, e faça o commit de novo. Nada se perdeu: o `git add` já tinha preparado o
arquivo, e o commit só precisava de um nome para pôr nele.

**O branch se chama `master`.** Um repositório criado antes de `init.defaultBranch` ser configurado fica
com o nome com que nasceu:

```
ana@laptop:~/project$ git commit -q -m "Say what the project is for" && git branch --show-current
master
ana@laptop:~/project$ git branch -m main && git branch --show-current
main
```

`git branch -m` renomeia o branch em que você está. Faça isso antes do primeiro push; depois dele, o site
de hospedagem tem um branch com o nome antigo também, e renomear os dois dá mais trabalho.

**A máquina virtual não liga.** Um hipervisor precisa do recurso de virtualização do processador, e alguns
computadores vêm com ele desligado nas configurações do firmware, onde se chama *Intel VT-x*, *AMD-V* ou
*SVM*. O VirtualBox avisa quando se recusa a ligar a máquina. Ligar o recurso é uma configuração do
firmware, aberta por uma tecla apertada enquanto o computador inicia, que muda de fabricante para
fabricante; a página de suporte do fabricante diz qual é.

**O codespace não está mais lá.** Um codespace parado sem uso é desligado, e depois apagado, no prazo que
o GitHub define. O que você fez commit e enviou está a salvo no repositório; o que não enviou foi junto
com ele. Envie ao fim de cada sessão de trabalho, o que é boa prática em qualquer caminho.

Se o seu erro não é nenhum destes, copie a **primeira** linha dele num buscador, entre aspas. A primeira
linha é a causa; as seguintes costumam ser consequências.
