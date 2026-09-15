---
title: O `apt`, e ler o que ele está prestes a fazer
version: 1
---

Aqui está uma instalação completa, sem edição, e ela vale ser lida antes de valer ser rodada:

```
root@vm:~# apt install cowsay
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  libtext-charwidth-perl
Suggested packages:
  filters cowsay-off
The following NEW packages will be installed:
  cowsay libtext-charwidth-perl
0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.
Need to get 27.9 kB of archives.
After this operation, 135 kB of additional disk space will be used.
Do you want to continue? [Y/n] y
Get:1 http://archive.ubuntu.com/ubuntu noble/main amd64 libtext-charwidth-perl amd64 0.04-11build3 [
9358 B]
Get:2 http://archive.ubuntu.com/ubuntu noble/universe amd64 cowsay all 3.03+dfsg2-8 [18.6 kB]
Fetched 27.9 kB in 0s (154 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libtext-charwidth-perl:amd64.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack .../libtext-charwidth-perl_0.04-11build3_amd64.deb ...
Unpacking libtext-charwidth-perl:amd64 (0.04-11build3) ...
Selecting previously unselected package cowsay.
Preparing to unpack .../cowsay_3.03+dfsg2-8_all.deb ...
Unpacking cowsay (3.03+dfsg2-8) ...
Setting up libtext-charwidth-perl:amd64 (0.04-11build3) ...
Setting up cowsay (3.03+dfsg2-8) ...
```

## O parágrafo antes da pergunta é o ponto inteiro

**Tudo acima de `Do you want to continue?` é o apt te contando o que ele decidiu**, e é a parte que
as pessoas atravessam apertando `y`. Quatro linhas dela respondem quatro perguntas diferentes:

**`The following additional packages will be installed:`** — você pediu um e está recebendo dois. O
`libtext-charwidth-perl` é o `Depends` do `cowsay` da seção 104, resolvido.

**`The following NEW packages will be installed:`** é a lista completa. Numa máquina real é aqui que
você repara que um utilitário pequeno está arrastando um servidor gráfico junto.

**`0 upgraded, 2 newly installed, 0 to remove and 168 not upgraded.`** é a de ler com cuidado, e o
número que importa é o terceiro. **O `to remove` deveria ser `0`** a menos que você quisesse — um
valor diferente ali é o apt te dizendo que atender ao seu pedido exige tirar algo, e é a coisa mais
útil na tela.

O `168 not upgraded` não tem relação com esta instalação: é o quanto a máquina está atrasada. A seção
111 é sobre o que fazer com esse número.

**`After this operation, 135 kB of additional disk space will be used.`** — e ele pode dizer `freed`
em vez disso, ou um número em gigabytes que explica por que o disco encheu da última vez.

## O `-y`, e quando não usá-lo

O `apt install -y` responde à pergunta por você. Ele pertence a um script, a um Dockerfile, a uma
tarefa do Ansible — a qualquer lugar em que ninguém está olhando.

**Ele não pertence a um terminal em que você está sentado**, porque a pergunta é o último momento
antes de o `to remove` virar realidade. Digite o comando, leia o parágrafo, e então decida.

## Desempacotar e configurar são dois passos

```
Unpacking cowsay (3.03+dfsg2-8) ...
Setting up cowsay (3.03+dfsg2-8) ...
```

Todo pacote passa pelos dois, e eles falham de formas diferentes:

| | |
|---|---|
| **desempacotar** | os arquivos são escritos no sistema de arquivos |
| **configurar** | o script de instalação do próprio pacote roda — usuários, diretórios, um serviço habilitado |

Um pacote pode estar desempacotado e não configurado, e a seção 109 mostra exatamente esse estado,
com o programa instalado e sem funcionar. **As duas letras do `dpkg -l` são esses dois passos**, uma
letra cada.

O `debconf: delaying package configuration, since apt-utils is not installed` naquela transcrição é
esta máquina sendo mínima: o `debconf` é o que faz as perguntas de instalação de um pacote, e sem
nada por onde fazê-las ele adia. Numa máquina instalada normalmente, é aqui que um pacote pararia e
te perguntaria algo.

## O conjunto do dia a dia

```
apt update                    # refresh the indexes
apt install thing             # install, with dependencies
apt remove thing              # uninstall, keeping its configuration
apt purge thing               # uninstall, configuration and all
apt autoremove                # drop dependencies nothing needs any more
apt upgrade                   # newer versions of everything installed
apt search text               # find something by name or description
apt show thing                # everything known about one package
apt list --installed          # what is on this machine
```

Nove comandos, e eles são a maior parte do que alguém digita. O `remove` contra o `purge` e para o
que serve o `autoremove` são a seção 110.

## O `apt` e o `apt-get` não são o mesmo comando

```
root@vm:~# apt list --installed 2>&1 | head -3

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.
```

O apt imprime isso quando a saída dele não é um terminal, e ele quer dizer o que diz. **O `apt` é
para pessoas e o `apt-get` é para scripts**: o `apt` tem barras de progresso, cor e um layout mais
amigável, e os autores dele reservam o direito de mudar tudo isso. O `apt-get` e o `apt-cache` não
mudam há décadas e não vão mudar.

Então: digite `apt` num prompt, e escreva `apt-get` em qualquer coisa que rode sem ninguém olhando.
As transcrições desta aula usam um ou outro conforme o que está sendo discutido, e o aviso acima é
por que você vai ver os dois.
