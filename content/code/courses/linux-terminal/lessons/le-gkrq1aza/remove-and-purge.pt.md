---
title: `remove`, `purge` e `autoremove`
version: 1
---

Desinstalar tem três comandos e eles fazem três coisas diferentes. Escolher o errado não é perigoso;
é só como uma máquina acaba com configuração de um software que foi embora dois anos atrás, e como
acontece o "reinstalei e ele continua com as minhas configurações antigas".

Aqui está tudo isso numa sessão só:

```
root@vm:~# apt-get install -y -qq screen
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package screen.
(Reading database ... 58861 files and directories currently installed.)
Preparing to unpack .../screen_4.9.1-1ubuntu1_amd64.deb ...
Unpacking screen (4.9.1-1ubuntu1) ...
Setting up screen (4.9.1-1ubuntu1) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. a
t /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 79.)
debconf: falling back to frontend: Readline
Processing triggers for debianutils (5.17build1) ...
root@vm:~# dpkg -l screen | tail -1
ii  screen         4.9.1-1ubuntu1 amd64        terminal multiplexer with VT100/ANSI terminal emulati
on
```

Instalado, `ii`. Agora remova:

```
root@vm:~# apt-get remove -y -qq screen
(Reading database ... 58921 files and directories currently installed.)
Removing screen (4.9.1-1ubuntu1) ...
Processing triggers for debianutils (5.17build1) ...
root@vm:~# dpkg -l screen | tail -1
rc  screen         4.9.1-1ubuntu1 amd64        terminal multiplexer with VT100/ANSI terminal emulati
on
root@vm:~# ls -l /etc/screenrc
-rw-r--r-- 1 root root 3663 Jun 20  2016 /etc/screenrc
```

**`rc`, e o arquivo de configuração continua lá.** Leia as duas letras com a legenda da seção 107:

| | |
|---|---|
| `r` | **desejado**: remover |
| `c` | **estado**: só os arquivos de configuração sobraram |

É o `remove` fazendo exatamente o que promete. O programa sumiu; o `/etc/screenrc` não.

Agora o purge:

```
root@vm:~# apt-get purge -y -qq screen
(Reading database ... 58863 files and directories currently installed.)
Purging configuration files for screen (4.9.1-1ubuntu1) ...
removed '/etc/tmpfiles.d/screen-cleanup.conf'
root@vm:~# dpkg -l screen | tail -1
dpkg-query: no packages found matching screen
root@vm:~# ls -l /etc/screenrc
ls: cannot access '/etc/screenrc': No such file or directory
```

**Sumiu do banco de dados e sumiu do disco.** O `dpkg -l` não tem mais linha nenhuma, que é a
diferença entre `rc` e nada.

## Qual usar

| | |
|---|---|
| `remove` | quando você pode recolocá-lo, e quer as suas configurações quando recolocar |
| `purge` | quando você terminou com ele, ou quando a configuração é o problema |

**O `purge` é a resposta certa bem mais vezes do que as pessoas o usam**, por um motivo específico: a
configuração de um pacote em `rc` é *reaproveitada* na reinstalação. Então o clássico "removi e
reinstalei e continua quebrado" é o `remove` funcionando corretamente — ele guardou a configuração
quebrada para você.

Achar o que ficou espalhado:

```
dpkg -l | grep '^rc'                        # packages that left configuration behind
dpkg -l | awk '/^rc/ {print $2}' | xargs apt-get purge -y
```

A segunda linha vale ser lida antes de rodada: ela pega os nomes da primeira coluna e dá purge em
todos. Numa máquina que atravessou algumas versões da distribuição, ela normalmente acha uma dúzia.

## O `autoremove`, e a marca que o dirige

```
root@vm:~# apt remove -y cowsay
The following package was automatically installed and is no longer required:
  libtext-charwidth-perl
Use 'apt autoremove' to remove it.
The following packages will be REMOVED:
  cowsay
0 upgraded, 0 newly installed, 1 to remove and 168 not upgraded.
After this operation, 93.2 kB disk space will be freed.
(Reading database ... 58935 files and directories currently installed.)
Removing cowsay (3.03+dfsg2-8) ...
root@vm:~# apt autoremove -y
The following packages will be REMOVED:
  libtext-charwidth-perl
0 upgraded, 0 newly installed, 1 to remove and 168 not upgraded.
(Reading database ... 58874 files and directories currently installed.)
Removing libtext-charwidth-perl:amd64 (0.04-11build3) ...
```

Remover o `cowsay` deixou o `libtext-charwidth-perl` para trás e disse isso. Ele não ficou órfão por
acidente: o apt o marcou como `auto` quando o trouxe para o `cowsay`, e **mais nada na máquina o
pediu**, então ele agora é candidato.

O `autoremove` junta todo pacote assim e os remove juntos. Rodá-lo depois de qualquer remoção grande
é como uma máquina fica do tamanho que deveria.

**Uma ressalva, e é real.** O `autoremove` confia na marca `auto`, e a marca pode estar errada — você
instalou A, ele trouxe B, e você passou a depender de B diretamente. O `apt-mark manual B` conserta
isso em definitivo, e a seção 108 é onde as marcas moram.

A versão para tomar cuidado é o `apt autoremove --purge`, que remove aqueles pacotes *e* a
configuração deles. É a coisa certa numa máquina que você está limpando e a coisa errada de rodar sem
ler a lista.

## Do lado rpm

```
dnf remove thing           # removes it, and anything that requires it
dnf autoremove             # the same idea as apt's
rpm -e thing               # the low layer: one package, and it refuses if something needs it
```

**Não há `purge`**, porque o rpm trata a configuração de outro jeito: um arquivo de configuração que
você editou é salvo como `.rpmsave` quando o pacote é removido, e um arquivo de configuração de um
pacote que foi atualizado pode aparecer como `.rpmnew` ao lado do seu. A seção 112 diz mais; a versão
curta é que o lado rpm deixa arquivos com extensões novas onde o lado Debian deixa uma linha de banco
de dados.
