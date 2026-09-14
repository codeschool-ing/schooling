---
title: `umask`, que decide com o que um arquivo novo nasce
version: 1
---

Ninguém te perguntou que permissões o `report.txt` deveria ter. Algo decidiu, e decidiu a mesma
coisa toda vez:

```
ana@vm:~/um$ umask
0022
ana@vm:~/um$ touch a.txt
ana@vm:~/um$ mkdir a.dir
ana@vm:~/um$ ls -l
total 4
drwxr-xr-x 2 ana ana 4096 Sep 14 22:45 a.dir
-rw-r--r-- 1 ana ana    0 Sep 14 22:45 a.txt
```

`644` para o arquivo, `755` para o diretório. Esses dois números são onde quase todo arquivo da
máquina começa, e o `0022` é o motivo.

## É uma máscara: ela diz o que tirar

Um programa criando um arquivo pede um modo. Quase todos pedem os mesmos dois:

| | pede |
|---|---|
| um **arquivo** | `666` — ler e escrever para todo mundo, e nenhuma execução |
| um **diretório** | `777` |

**Ninguém recebe o que pediu.** O kernel remove cada bit que a umask tiver ligado, e o que sobra é
o modo:

| | arquivo | diretório |
|---|---|---|
| pedido | `666` | `777` |
| umask | `022` | `022` |
| **resultado** | **`644`** | **`755`** |

Tire o dígito da umask do dígito pedido — `6 - 0 = 6`, `6 - 2 = 4`, `6 - 2 = 4` — e você tem `644`.
A subtração só funciona porque os dígitos casam aqui; o que realmente acontece é que cada bit ligado
na máscara é desligado no resultado. Onde os dois divergem é um caso que você não vai encontrar: uma
umask de `7` contra um pedido de `6` dá `0`, e não `-1`.

**Repare no que a umask não consegue fazer.** Ela só remove. Uma umask de `000` te dá `666` e `777`,
e nunca um arquivo com `x`, porque ninguém pediu `x` em primeiro lugar. É por isso que um script
novo não é executável e você precisa dizer `chmod +x` — seção 58.

## Mudar, e ver funcionando

```
ana@vm:~/um$ umask 077
ana@vm:~/um$ touch b.txt
ana@vm:~/um$ mkdir b.dir
ana@vm:~/um$ ls -l
total 8
drwxr-xr-x 2 ana ana 4096 Sep 14 22:45 a.dir
-rw-r--r-- 1 ana ana    0 Sep 14 22:45 a.txt
drwx------ 2 ana ana 4096 Sep 14 22:45 b.dir
-rw------- 1 ana ana    0 Sep 14 22:45 b.txt
```

`077` remove tudo de grupo e outros: `600` e `700`. E olhe o `a.txt` e o `a.dir` — **inalterados.**
Uma umask vale quando um arquivo é criado, e nunca mais.

O outro sentido:

```
ana@vm:~/um$ umask 002
ana@vm:~/um$ touch c.txt
ana@vm:~/um$ ls -l c.txt
-rw-rw-r-- 1 ana ana 0 Sep 14 22:45 c.txt
```

`664` — o grupo escreve. É a umask de quem trabalha num diretório compartilhado, e é com o que o
bit setgid da seção 63 normalmente anda junto.

O `-S` imprime ao contrário, como o que é *permitido* em vez do que é removido:

```
ana@vm:~/um$ umask -S
u=rwx,g=rx,o=rx
```

Mais fácil de ler, e o mesmo fato.

## Os três valores que você vai encontrar

| | arquivos | diretórios | para |
|---|---|---|---|
| `022` | 644 | 755 | o padrão na maioria das distribuições |
| `002` | 664 | 775 | trabalho compartilhado — o grupo escreve |
| `077` | 600 | 700 | privado — servidores que lidam com algo sensível |

**O `027` é o que vale conhecer em servidor**: arquivos `640`, diretórios `750`. O grupo lê,
estranhos não veem nada. É um ajuste comum de endurecimento, e quebra software que supôs `022`, que
é como se descobre que ele foi configurado.

## De onde ela vem e como mudar de vez

A umask que você tem é definida no login, e pode vir de três ou quatro lugares:

| | |
|---|---|
| `/etc/login.defs` | `UMASK 022`, o padrão do sistema no Debian e no Ubuntu |
| `pam_umask` | como esse padrão é de fato aplicado no login |
| `/etc/profile`, `/etc/bash.bashrc` | um ajuste de shell para a máquina inteira |
| `~/.bashrc`, `~/.profile` | o seu, para shells interativos |

Digitar `umask 077` num prompt muda o shell atual e os filhos dele, e mais nada. Some quando você
sai.

**Uma umask no `~/.bashrc` não vale para um serviço.** Um serviço é iniciado pelo systemd, não pelo
seu shell, e ele tem a dele — o `UMask=` num arquivo de unit, na aula 5. Quando um daemon escreve
arquivos com a permissão errada, é ali que se olha, e editar os seus dotfiles não vai encostar
nisso.

## Duas coisas que não obedecem

**`cp -p` e `tar -x` restauram os modos que gravaram.** É esse o objetivo de preservar permissões, e
é por isso que um arquivo extraído de um pacote pode ser mais aberto que qualquer coisa que você
conseguisse criar à mão.

**O `chmod` é absoluto.** `chmod 666 arquivo` te dá `666`, com umask ou sem. A máscara é sobre
*criação*, e o `chmod` não é criação.

Há uma exceção que vale nomear, porque parece contradição: **`chmod +x` sem `u`, `g` ou `o` é
filtrado pela umask.**

```
ana@vm:~/uq$ umask 077
ana@vm:~/uq$ chmod 600 t1.txt t2.txt
ana@vm:~/uq$ chmod +x t1.txt
ana@vm:~/uq$ chmod a+x t2.txt
ana@vm:~/uq$ ls -l
total 0
-rwx------ 1 ana ana 0 Sep 14 22:57 t1.txt
-rwx--x--x 1 ana ana 0 Sep 14 22:57 t2.txt
```

A mesma intenção, dois resultados diferentes. O `+x` pelado foi filtrado e deu só o dono; o `a+x`
disse quem, e não foi filtrado. **Escreva o público** e isso nunca aparece.
