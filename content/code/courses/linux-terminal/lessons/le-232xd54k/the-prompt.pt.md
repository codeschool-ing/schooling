---
title: Lendo o prompt
version: 1
---

O prompt é a primeira coisa na tela e a última que alguém explica. Ele não é enfeite e não é logo:
**é uma frase que o shell escreve, e cada pedaço dela responde uma pergunta que você teria de
fazer.**

```
ana@vm:~$
```

Quatro pedaços, da esquerda para a direita: `ana`, `vm`, `~`, `$`.

## Quem, onde, e o que você pode fazer

| pedaço | pergunta que responde | por que importa |
|---|---|---|
| `ana` | **quem** você é nesta máquina | permissões seguem o usuário, não a pessoa |
| `vm` | **qual máquina** é esta | a melhor defesa que existe contra rodar algo no servidor errado |
| `~` | **onde** você está no sistema de arquivos | todo comando age aqui, salvo ordem em contrário |
| `$` | se você é **root** | `$` é usuário comum, `#` é o administrador |

Os dois do meio são os que te salvam. Quando você está conectado em quatro máquinas em quatro
abas, o nome do host é o que impede você de reiniciar a produção porque ela parecia a homologação.
E o diretório é o motivo de `rm *` ser um comando diferente em dois lugares diferentes.

## Ele se mexe, porque está te dizendo algo

A parte do diretório é viva. Veja mudar:

```
ana@vm:~$ pwd
/home/ana
ana@vm:~$ cd /etc
ana@vm:/etc$ pwd
/etc
ana@vm:/etc$ cd ~/notas
ana@vm:~/notas$
```

Duas coisas para levar daí.

**`~` é o seu diretório pessoal, escrito curto.** O prompt mostrou `~` e o `pwd` respondeu
`/home/ana`, que é o mesmo lugar dito de dois jeitos. Quando você vai para fora da sua casa, o
prompt escreve o caminho por extenso — `/etc` — e quando você volta para dentro dela, ele encurta
de novo: `~/notas` é `/home/ana/notas`.

**`pwd` e o prompt concordam porque estão lendo o mesmo fato.** Se você duvidar do prompt, o `pwd`
é a pergunta direta. A seção 36 da aula 3 aprofunda o que "diretório atual" significa; aqui basta
que o shell está sempre em um, e sempre diz em qual.

## O `#` é um aviso, não um enfeite

```
root@vm:/home/ana# whoami
root
```

`#` no lugar de `$` quer dizer que todo comando que você digitar roda sem restrição nenhuma. Nada
vai te perguntar se você tem certeza. O sistema vai deixar você apagar os arquivos que fazem dele
um sistema.

É essa a razão de o prompt padrão se dar ao trabalho de distinguir os dois, e vale treinar o
reflexo agora: **olhe o último caractere antes de apertar enter em qualquer coisa destrutiva.** A
seção 14 explica por que você não é root por padrão, e a seção 61 da aula 4 explica o `sudo`, que é
como se vira root por um comando em vez de por uma noite inteira.

## Quem escreve é o shell, então ele é seu para mudar

O prompt é um texto numa variável chamada `PS1`, montado a partir de códigos de escape:

```
ana@vm:~$ echo "$PS1"
${debian_chroot:+($debian_chroot)}\u@\h:\w\$
```

`\u` é o usuário, `\h` o host, `\w` o diretório de trabalho, `\$` o `$`-ou-`#`. O resto da linha é
o Ubuntu sendo cuidadoso com um caso que você não tem.

Não se espera que você escreva um desses hoje. O que importa é a conclusão: **o prompt é uma
decisão que alguém tomou, não uma propriedade do Linux.** Em outra máquina ele pode ser um
caractere só. Pode ser verde. Pode ter a hora, o branch do git, ou nada. Quando você chegar em
algum lugar e o prompt parecer estranho, não há nada errado — pergunte direto à máquina com
`whoami`, `hostname` e `pwd`, que são as três perguntas que o prompt padrão respondia para você.

## Quando não há prompt

Um prompt quer dizer que **o shell está pronto e esperando você**. Nenhum prompt quer dizer que
não está.

```
ana@vm:~$ sleep 30
```

Nada mais acontece, o cursor fica parado ali, e nada do que você digita parece fazer efeito. A
máquina não travou: um comando está rodando, e o shell não vai falar de novo até ele terminar. Esse
é o estado normal e saudável de qualquer comando que leva tempo.

As duas perguntas que vale separar, porque têm respostas diferentes:

- **Está trabalhando, ou está travado?** Pelo prompt você não tem como saber. A aula 6 te dá o
  `ps` e o `top`, que são como se descobre de verdade.
- **Como eu paro isso?** `Ctrl+C`, e a seção depois da próxima explica o que essa tecla realmente
  envia e por que nem sempre basta.

Aprender a ler esse estado é a maior parte da diferença entre alguém confortável num terminal e
alguém que vai atrás do botão de desligar.
