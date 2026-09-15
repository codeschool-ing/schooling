---
title: Um programa que sobrevive à sua sessão
version: 1
---

Tudo que você rodou até agora começou quando você digitou e parou quando terminou. Um **serviço** é
o outro tipo: um programa que começa sem ninguém pedir, continua rodando quando você sai, e ainda
está lá depois de um reboot.

Um servidor web. Um banco de dados. O servidor ssh que você usou na seção 75 — **alguma coisa tinha
de estar escutando antes de você conectar**, e ninguém estava logado para iniciá-la.

## A palavra mais antiga é *daemon*

Você vai ver as duas, e elas querem dizer a mesma coisa. *Daemon* é a palavra do Unix, e a convenção
é que o nome do programa termine em `d`: `sshd`, `httpd`, `crond`, `systemd`. **O `d` é a palavra.**

Não é um demônio. O nome vem do demônio de Maxwell na física — um agente de bastidor fazendo
trabalho que ninguém observa — e a grafia é deliberada.

*Serviço* é a palavra moderna, e é como o `systemctl` chama as coisas. Use a que a ferramenta à sua
frente usar.

## O que de fato faz de um programa um daemon

Três propriedades, e cada uma é algo que um programa precisa fazer de propósito:

**Ele não tem terminal.** A seção 03 da aula 1 disse que um processo lê de um terminal e escreve
num. Um daemon se desliga de qualquer terminal em que tenha sido iniciado, e é por isso que fechar a
janela que o iniciou não o para — e por isso que a saída dele precisa ir para outro lugar, que é o
assunto inteiro da seção 81.

**O pai dele é o PID 1.** O pai original de um daemon termina, e o kernel readota o órfão no
processo um. A aula 6 trata de readoção direito; a consequência visível é que um daemon pertence ao
sistema, e não a uma sessão.

**Ele roda com a própria conta.** A seção 71 contou trinta contas e uma pessoa, e é para isso que
servem as outras vinte e nove. Um servidor web rodando como `www-data` que for invadido entrega ao
atacante o `www-data`, que lê o site e quase nada mais.

Serviços modernos não se desligam na mão mais. **O systemd os inicia em primeiro plano e faz o
desligamento ele mesmo** — e é por isso que `Type=simple` na seção 80 é o caso comum, e por que um
programa escrito para virar daemon do jeito antigo precisa de `Type=forking` para avisar.

## Onde um serviço guarda as coisas dele

Os mesmos quatro lugares, sempre, e conhecê-los é a maior parte de se achar num serviço
desconhecido:

| | |
|---|---|
| `/etc/<nome>/` | a configuração — texto, seção 37 |
| `/var/lib/<nome>/` | os dados de trabalho. Os arquivos de um banco ficam aqui |
| `/var/log/<nome>/` | os logs, se ele escrever arquivos em vez de usar o journal |
| `/run/<nome>/` | o arquivo de PID e o socket, que somem no boot |
| `/usr/lib/systemd/system/<nome>.service` | como ele é iniciado — seção 80 |

Ou seja: **o `nginx` são cinco caminhos que você adivinha antes de olhar.** É esse o retorno de a
seção 37 da aula 3 ser um padrão e não um costume.

## Três coisas de que um serviço precisa e um comando não

**Alguém para iniciá-lo no boot.** Isso é o assunto inteiro das seções 77 e 78, e a razão de o verbo
`enable` existir separado do `start`.

**Algum lugar para a saída dele ir.** Um comando imprime no seu terminal. Um daemon não tem um,
então cada linha que ele escreve precisa ser recolhida por alguma coisa — um arquivo de log, ou o
journal da seção 81.

**Alguém para perceber quando ele morre.** Um comando que quebra te deixa um código de saída para
olhar. Um daemon que quebra às três da manhã não deixa nada, a menos que quem o iniciou estivesse
observando. `Restart=on-failure` na seção 80 é isso, numa linha.

Essas três necessidades são exatamente o que um sistema de init fornece, e são a razão de um
existir.

## Nem tudo que roda é um serviço

Uma máquina tem três tipos de processo de longa duração, e eles são geridos de forma diferente:

| | iniciado por | exemplo |
|---|---|---|
| **um serviço** | o sistema de init, no boot | `sshd`, `nginx` |
| **uma tarefa agendada** | o cron ou um timer, numa hora | um backup noturno — aula 13 |
| **uma tarefa em segundo plano** | você, de um shell | `tail -f &` — aula 6 |

A terceira some quando sua sessão termina, a menos que você tome providências — a seção 96 da aula 6
é exatamente sobre isso, e é a diferença entre uma coisa que sobrevive à queda do seu ssh e uma que
não.

**Quando alguém diz "parou de funcionar quando eu saí", a resposta é que aquilo nunca foi um
serviço.** Era a terceira linha, rodando numa sessão que acabou.
