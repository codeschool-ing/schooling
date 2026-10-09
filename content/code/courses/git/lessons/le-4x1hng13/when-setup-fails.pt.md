---
title: Quando a instalação não funciona
version: 1
---

Tudo nas duas últimas seções pode dar errado, e quase todo jeito de dar errado imprime uma frase
que diz qual foi. Leia a frase antes de qualquer outra coisa. As do Git costumam ser exatas, e a
linha que começa com `fatal:` ou `error:` é a que nomeia o problema.

## `command not found`

Quem responde é o shell, não o Git: não existe programa com esse nome nesta máquina. Ou o Git não
está instalado na máquina em que você está digitando, ou o comando foi escrito errado. Descubra
qual com `git --version`. Se esse também não for encontrado, volte ao caminho que você escolheu
duas seções atrás e instale. Dentro da máquina virtual é `sudo apt install git`.

## `not a git repository`

```
ana@vm:~$ git status
fatal: not a git repository (or any of the parent directories): .git
ana@vm:~$ cd first
ana@vm:~/first$ git status --short
A  notes.txt
```

O Git está instalado e funcionando, e você está na pasta errada. Todo comando que lê um histórico
procura a pasta oculta `.git` de um repositório, primeiro onde você está e depois em cada pasta
acima, e na sua pasta pessoal não há nenhuma. O prompt diz onde você está: `~` é a pasta pessoal,
`~/first` é o repositório. Entre nele com `cd` e o mesmo comando responde. Este é o erro que você
mais vai ver neste curso, e ele nunca é mais do que isso.

## `is not a git command`

```
ana@vm:~/first$ git comit -m "Start the notes"
git: 'comit' is not a git command. See 'git --help'.

The most similar command is
	commit
```

Um erro de digitação depois de `git`, e o Git sugere o que você provavelmente quis dizer. A mesma
mensagem, sem sugestão, tem outra causa: um Git mais antigo que a 2.23 respondendo a `git switch`
ou `git restore`. Se `git --version` imprimir um número menor que esse, instale uma versão mais
nova. O caminho da máquina virtual não tem esse problema.

## Um nome sem aspas

Este não imprime nada, e é isso que faz valer a pena conhecê-lo:

```
ana@vm:~/first$ git config --global user.name Ana Souza
ana@vm:~/first$ git config --global user.name
Ana
ana@vm:~/first$ git config --global user.name "Ana Souza"
ana@vm:~/first$ git config --global user.name
Ana Souza
```

Sem aspas, o shell entrega duas palavras ao Git, e o Git toma a primeira como valor e a segunda
como outra coisa completamente diferente. O comando dá certo, e todo commit dali em diante leva
meio nome. **Pedir uma configuração sem valor imprime o que ela guarda**, e é assim que se confere
qualquer um dos quatro comandos da seção anterior.

## Um editor que não está lá

```
ana@vm:~/first$ git config --global core.editor "code --wait"
ana@vm:~/first$ git commit
code --wait: 1: code: not found
error: There was a problem with the editor 'code --wait'.
Please supply the message using either -m or -F option.
```

`code --wait` é o que muitos guias sugerem, e abre o Visual Studio Code, que não está instalado
dentro de uma máquina virtual. O Git faz o que a configuração manda, falha, e não faz commit
nenhum. O conserto é definir um editor que a máquina tem: `git config --global core.editor nano`.

A armadilha oposta não tem mensagem de erro. Sem editor definido, o Git pode abrir o vim, e um
commit parece travar numa tela cheia de `~`. Ele está esperando uma mensagem. Aperte Esc, digite
`:q!` e Enter para sair sem fazer o commit, e depois defina o nano como acima.

## Abaixo de tudo isso: a própria máquina virtual

Se o hipervisor se recusar a ligar a máquina com uma mensagem sobre `VT-x`, `AMD-V` ou
virtualização desativada, **o processador sabe fazer isso e o firmware do computador está com o
recurso desligado.** É uma opção no menu da BIOS ou UEFI, aberto por uma tecla apertada enquanto o
computador liga, e o site do fabricante diz qual tecla. Se você não puder mudá-la, o caminho
instalado ou o online não precisam de virtualização nenhuma.

## Começar de novo

Nada aqui é precioso ainda. `rm -rf ~/first` apaga o repositório de treino, com a pasta `.git` e
tudo, e a seção anterior o cria de novo em quatro linhas. Se a própria máquina estiver num estado
que você não sabe explicar, apague-a no hipervisor e faça outra. É para isso que serve uma máquina
virtual.
