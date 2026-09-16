---
title: Que versão você recebeu, e como impedir que ela mude
version: 1
---

O `apt policy` responde à pergunta que ninguém pensa em fazer até algo dar errado: **de onde veio
esta versão, e o que mais estava em oferta?**

```
root@vm:~# apt policy cowsay
cowsay:
  Installed: (none)
  Candidate: 3.03+dfsg2-8
  Version table:
     3.03+dfsg2-8 500
        500 http://archive.ubuntu.com/ubuntu noble/universe amd64 Packages
```

Três coisas:

| | |
|---|---|
| `Installed` | o que está na máquina agora, ou `(none)` |
| `Candidate` | o que o `apt install` te daria |
| `Version table` | toda versão que qualquer repositório configurado oferece |

**`Candidate` é a palavra a guardar.** Ela não é "a versão mais nova que existe" — é a mais nova que
o apt está disposto a te dar dos repositórios que você tem, nas prioridades deles.

## Prioridades, e o número na frente da URL

```
root@vm:~# apt policy docker-ce 2>/dev/null | head -12
docker-ce:
  Installed: 5:29.3.1-1~ubuntu.24.04~noble
  Candidate: 5:29.8.0-1~ubuntu.24.04~noble
  Version table:
     5:29.8.0-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.2-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.1-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
     5:29.7.0-1~ubuntu.24.04~noble 500
        500 https://download.docker.com/linux/ubuntu noble/stable amd64 Packages
```

Esta é uma máquina real atrasada no Docker: instalada `29.3.1`, candidata `29.8.0`, e quatro versões
intermediárias que o repositório ainda carrega.

**O `500` é a prioridade.** Toda versão ganha uma, e o apt escolhe a de maior prioridade, usando a
mais nova para desempatar. Os padrões valem ser conhecidos porque explicam mais do que parece:

| | |
|---|---|
| `100` | já instalado, ou vindo do `noble-backports` |
| `500` | um repositório normal |
| `990` | a versão que você de fato mira |
| `< 0` | nunca instale isto |
| `1001+` | instale isto mesmo que signifique **rebaixar** |

O `100` para "já instalado" é o silencioso. **É por isso que um pacote instalado nunca é rebaixado
automaticamente** — qualquer coisa de um repositório o supera em 500, mas nada o empurra para fora em
favor de algo mais antigo.

Aquele `5:` na frente das versões do Docker é o epoch da seção 02. Leia depois dele: `29.8.0` contra
`29.3.1`.

## Segurar uma versão

```
root@vm:~# apt-mark hold cowsay
cowsay set on hold.
root@vm:~# apt-mark showhold
cowsay
root@vm:~# apt-get install -y --only-upgrade cowsay
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
cowsay is already the newest version (3.03+dfsg2-8).
0 upgraded, 0 newly installed, 0 to remove and 168 not upgraded.
root@vm:~# apt-mark unhold cowsay
Canceled hold on cowsay.
root@vm:~# apt-mark showhold; echo "(empty above means none held)"
(empty above means none held)
```

**Um hold quer dizer que o `upgrade` vai pular aquele pacote**, em silêncio, enquanto o hold estiver
lá. É a ferramenta certa para um banco de dados ou um kernel que não pode se mexer sem uma janela de
manutenção.

E é uma armadilha que você arma para um colega. O pacote para de atualizar, o `apt upgrade` não diz
nada sobre ele, e o único jeito de descobrir é o `apt-mark showhold`. **Quando um pacote está
misteriosamente preso numa versão antiga, esse é o primeiro comando a rodar** — e quando você põe um
hold, anote por quê, em algum lugar que não seja a máquina.

O `dpkg --get-selections | grep hold` é o outro jeito de vê-los, e o `dpkg -l` mostra `h` na primeira
coluna de um pacote segurado.

## Instalar uma versão específica

```
apt install cowsay=3.03+dfsg2-8        # exactly this version
apt policy cowsay                      # to find out what the choices are
```

A versão precisa estar na tabela que o `apt policy` imprimiu. **Um repositório normalmente carrega
uma versão de cada pacote**, que é por que isso funciona no repositório do Docker acima — ele guarda
várias — e falha no do Ubuntu, que não guarda.

Voltar atrás precisa de mais do que um número de versão: o `apt install coisa=versaoantiga` vai
fazer, e o apt vai avisar que é um rebaixamento. Rebaixamentos não são suportados pelo empacotamento
em geral, porque o script de instalação de um pacote é escrito para atualizar de versões mais antigas
e não de mais novas. **O jeito confiável de voltar é dar purge e instalar a versão antiga**, e o
jeito confiável de não precisar disso é testar antes de atualizar.

## Pinning, quando um hold não basta

Um hold prende um pacote no que quer que ele seja agora. Um **pin** expressa uma regra, em
`/etc/apt/preferences.d/`:

```
Package: docker-ce
Pin: version 5:29.3.*
Pin-Priority: 1001
```

Isso diz "a candidata do `docker-ce` é qualquer release `29.3`, e instale mesmo que seja um
rebaixamento". A prioridade `1001` é o número acima de 1000 da tabela, que é a única faixa que
permite andar para trás.

A outra comum é a oposta — impedir um repositório de terceiro inteiro de tomar conta:

```
Package: *
Pin: origin download.docker.com
Pin-Priority: 100
```

**Isso põe todo pacote daquela origem abaixo de "já instalado"**, então nada dela é instalado a menos
que você peça pelo nome. É a defesa padrão contra um repositório de terceiro que também carrega
versões de coisas que a sua distribuição já fornece, que é a seção 13.

O `apt-cache policy` sem pacote imprime as prioridades em vigor, que é como você confere se um
arquivo de pin diz o que você quis dizer.

## Do lado rpm

```
dnf --showduplicates list thing     # every version the repositories have
dnf install thing-1.2.3             # a specific one
dnf downgrade thing                 # supported, and it means it
dnf versionlock add thing           # the hold, from the dnf-plugins-core package
```

**O `dnf downgrade` é um comando de primeira classe**, que é a única diferença real desta seção entre
as duas famílias. O `/etc/dnf/dnf.conf` também pode carregar linhas `exclude=`, que é a forma mais
grosseira de um pin.
