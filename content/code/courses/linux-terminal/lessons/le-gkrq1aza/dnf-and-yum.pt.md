---
title: `dnf`, `yum` e `rpm`
version: 1
---

**Um aviso sobre esta seção antes de tudo.** A máquina em que estas transcrições foram capturadas é
Ubuntu. O `rpm`, o `dnf` e o `zypper` estão instalados nela, e os pacotes das transcrições vêm de um
repositório construído para esta aula — dois pacotes pequenos, um dos quais precisa do outro, num
diretório com um índice por cima.

Então **os comandos, as opções deles e a saída deles são reais e foram rodados**, e a distribuição
não é Red Hat. Duas consequências aparecem na saída e são apontadas onde aparecem. Todo o resto desta
página é o que você veria no Rocky, no Alma, no Fedora ou no RHEL.

## O `yum` é o `dnf`

O `yum` era a ferramenta; o `dnf` foi a reescrita; em qualquer sistema atual da família Red Hat **o
`yum` é um symlink para o `dnf`** e todo comando abaixo funciona com qualquer um dos dois nomes. Você
vai encontrar o `yum` em documentação, em Dockerfiles e na memória muscular, e digitá-lo não é erro.

O Fedora 41 em diante traz o `dnf5`, que são os mesmos comandos de novo com entranhas mais rápidas e
formatação de saída um pouco diferente.

## O arquivo de repositório

```
root@vm:~# cat /etc/yum.repos.d/teaching.repo
[teaching]
name=A local repository, built for this lesson
baseurl=file:///srv/teaching-repo
enabled=1
gpgcheck=0
root@vm:~# dnf repolist
repo id                           repo name
teaching                          A local repository, built for this lesson
```

Esta é a forma de todo arquivo `.repo` do `/etc/yum.repos.d/`:

| | |
|---|---|
| `[teaching]` | o **repo id**, que é a que os comandos se referem |
| `name=` | o rótulo humano |
| `baseurl=` | onde ele está. `mirrorlist=` ou `metalink=` no lugar, para uma lista de espelhos |
| `enabled=1` | se ele é usado sem ser pedido |
| `gpgcheck=1` | **verificar assinaturas de pacote**. O repo desta aula não é assinado, daí o `0` |

**O `gpgcheck=0` é o que não copiar.** Ele está aqui porque estes dois pacotes foram construídos
nesta máquina minutos antes, sem chave. Em qualquer coisa real ele é `1`, com `gpgkey=` nomeando a
chave — é o lado rpm do `signed-by` da seção 105.

A equivalência a guardar: **um arquivo `.repo` aqui é um arquivo `.list` ou `.sources` no
`/etc/apt/sources.list.d/`.** Mesmo trabalho, sintaxe diferente.

## Achar e ler

```
root@vm:~# dnf search greet
Last metadata expiration check: 0:07:43 ago on Tue Sep 15 08:38:01 2026.
================================== Name & Summary Matched: greet ===================================
greet.noarch : Print a greeting, for teaching package managers
greet-tools.noarch : Extra commands that need greet
root@vm:~# dnf info greet
Last metadata expiration check: 0:07:48 ago on Tue Sep 15 08:38:01 2026.
Available Packages
Name         : greet
Version      : 1.2.0
Release      : 1
Architecture : noarch
Size         : 6.4 k
Source       : greet-1.2.0-1.src.rpm
Repository   : teaching
Summary      : Print a greeting, for teaching package managers
License      : MIT
Description  : A two-line shell script that prints a greeting. It exists so that a
             : package manager has something real to install, remove and query.
```

**O `Last metadata expiration check` é a linha que substitui o `apt update`.** O dnf atualiza os
próprios metadados quando o cache está mais velho que o `metadata_expire` — um dia, por padrão —
então não há passo de update separado e não há "mas eu atualizei". O `dnf --refresh` força, e o `dnf
makecache` é a versão explícita.

O `Available Packages` no topo do `info` é o dnf dizendo que este não está instalado. Depois de
instalar, o mesmo comando diz `Installed Packages`.

## Instalar, e a dependência

```
root@vm:~# dnf install greet-tools
Last metadata expiration check: 0:08:05 ago on Tue Sep 15 08:38:01 2026.
Dependencies resolved.
====================================================================================================
 Package                   Architecture         Version                Repository              Size
====================================================================================================
Installing:
 greet-tools               noarch               0.3.0-1                teaching               6.2 k
Installing dependencies:
 greet                     noarch               1.2.0-1                teaching               6.4 k

Transaction Summary
====================================================================================================
Install  2 Packages

Total size: 13 k
Installed size: 89
Is this ok [y/N]: y
Downloading Packages:
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                            1/1
  Installing       : greet-1.2.0-1.noarch                                                       1/2
  Installing       : greet-tools-0.3.0-1.noarch                                                 2/2
  Verifying        : greet-1.2.0-1.noarch                                                       1/2
  Verifying        : greet-tools-0.3.0-1.noarch                                                 2/2

Installed:
  greet-1.2.0-1.noarch                          greet-tools-0.3.0-1.noarch               

Complete!
root@vm:~# greet-twice
hello from greet 1.2.0
hello from greet 1.2.0
```

Compare aquela tabela com o parágrafo do apt na seção 106. **A mesma informação, disposta em vez de
escrita**, e com as seções nomeadas: `Installing:` é o que você pediu, `Installing dependencies:` é o
que veio junto.

Duas coisas que o apt não tem. **O `Is this ok [y/N]` tem "não" como padrão** — um Enter sozinho
cancela, onde o `[Y/n]` do apt prossegue. E a transação é conferida e testada antes de qualquer coisa
ser escrita, que são as linhas `Transaction check` e `Transaction test`: o dnf verifica o plano
inteiro contra o sistema de arquivos primeiro, então um conflito é achado antes de nenhum arquivo ter
se mexido.

## O `rpm`, a camada de baixo

```
root@vm:~# rpm -q greet
greet-1.2.0-1.noarch
root@vm:~# rpm -qi greet | head -8
Name        : greet
Version     : 1.2.0
Release     : 1
Architecture: noarch
Install Date: Tue Sep 15 08:46:10 2026
Group       : Unspecified
Size        : 66
License     : MIT
root@vm:~# rpm -ql greet
/usr/bin/greet
/usr/share/doc/greet/README
root@vm:~# rpm -qf /usr/bin/greet
greet-1.2.0-1.noarch
root@vm:~# rpm -qR greet-tools
greet >= 1.2.0
rpmlib(CompressedFileNames) <= 3.0.4-1
rpmlib(FileDigests) <= 4.6.0-1
rpmlib(PayloadFilesHavePrefix) <= 4.0-1
```

**Toda consulta do `rpm` começa com `-q`**, e a segunda letra escolhe a pergunta. É essa a interface
inteira e ela vale ser decorada em grupo:

| | | |
|---|---|---|
| `rpm -q coisa` | `dpkg -l coisa` | está instalado, e em que versão |
| `rpm -qi coisa` | `apt show coisa` | tudo que se sabe sobre ele |
| `rpm -ql coisa` | `dpkg -L coisa` | os arquivos que ele possui |
| `rpm -qf /caminho` | `dpkg -S /caminho` | **qual pacote possui este arquivo** |
| `rpm -qR coisa` | `apt-cache depends` | do que ele precisa |
| `rpm -qa` | `dpkg -l` | tudo que está instalado |

O `rpm -qR greet-tools` mostra o `greet >= 1.2.0` que o pacote desta aula declara, mais três entradas
`rpmlib(...)`. Essas não são pacotes: são **requisitos sobre o próprio formato rpm**, e todo rpm os
tem. Leia por cima.

## O `rpm -i` também não resolve nada

```
root@vm:~# rpm -q greet greet-tools
package greet is not installed
package greet-tools is not installed
root@vm:~# rpm -i /srv/teaching-repo/greet-tools-0.3.0-1.noarch.rpm
rpm: RPM should not be used directly install RPM packages, use Alien instead!
rpm: However assuming you know what you are doing...
error: Failed dependencies:
        greet >= 1.2.0 is needed by greet-tools-0.3.0-1.noarch
```

**O `error: Failed dependencies:` é a versão do `rpm` para a mensagem da seção 109**, e há uma
diferença que vale notar: o rpm recusa de saída. O dpkg desempacota e deixa o pacote meio instalado;
o rpm não escreve nada.

Aquelas duas linhas `rpm:` acima do erro são o primeiro dos dois artefatos de Ubuntu que as
transcrições rpm desta aula carregam; o outro está na seção 113. **O Debian e o Ubuntu trazem um
invólucro em volta do `rpm` que avisa que você está no tipo errado de sistema**, e então o roda assim
mesmo. No Rocky ou no Fedora elas não estão lá.

A remoção é recusada do mesmo jeito:

```
root@vm:~# rpm -e greet
error: Failed dependencies:
        greet >= 1.2.0 is needed by (installed) greet-tools-0.3.0-1.noarch
```

O `(installed)` é a palavra útil: algo nesta máquina precisa dele. O `rpm -e greet-tools greet` nomeia
os dois e funciona.

## Removendo com o dnf

```
root@vm:~# dnf remove greet
Dependencies resolved.
====================================================================================================
 Package                   Architecture         Version               Repository               Size
====================================================================================================
Removing:
 greet                     noarch               1.2.0-1               @teaching                66
Removing dependent packages:
 greet-tools               noarch               0.3.0-1               @teaching                23
```

**O `Removing dependent packages:` é o mesmo comportamento que a seção 108 mostrou o apt tendo** —
pedir um e ouvir dois. O `@` em `@teaching` quer dizer "instalado, e veio de lá", que é como o dnf
marca a origem de um pacote instalado.

## O conjunto de comandos

```
dnf install thing              dnf remove thing
dnf upgrade                    dnf check-update
dnf search text                dnf info thing
dnf list installed             dnf provides '*/bin/pdftotext'
dnf repolist                   dnf history
dnf autoremove                 dnf clean all
```

Dois sem equivalente no apt que valem conhecer:

**O `dnf provides` responde à quarta pergunta da seção 107 sem download extra**, porque os metadados
de repositório rpm incluem listas de arquivos:

```
root@vm:~# dnf provides '*/bin/greet'
Last metadata expiration check: 0:20:51 ago on Tue Sep 15 08:38:01 2026.
greet-1.2.0-1.noarch : Print a greeting, for teaching package managers
Repo        : teaching
Matched from:
Filename    : /usr/bin/greet
```

Isso é o `apt-file` sem os 346 MB. O glob importa: o `dnf provides pdftotext` procura um pacote que
*forneça a capacidade* `pdftotext`, e o `'*/bin/pdftotext'` procura um que entregue um arquivo
naquele caminho. Ponha entre aspas, ou o shell o expande antes.

**O `dnf history` é um registro de transações**, para o qual o apt não tem equivalente:

```
root@vm:~# dnf history | head -6
ID     | Command line                                  | Date and time    | Action(s)      | Altered
----------------------------------------------------------------------------------------------------
     4 | remove greet                                  | 2026-09-15 08:46 | Removed        |    2
     3 | install greet-tools                           | 2026-09-15 08:46 | Install        |    2
     2 | -y remove greet-tools greet                   | 2026-09-15 08:38 | Removed        |    2
     1 | -y --refresh install greet-tools              | 2026-09-15 08:38 | Install        |    2
```

Toda transação, com a linha de comando que a causou e quantos pacotes ela tocou. **O `dnf history
undo 3` desfaz uma**, e o `dnf history info 3` mostra em detalhe o que ela fez.

O equivalente mais próximo no apt é ler o `/var/log/apt/history.log`, que registra os mesmos fatos e
não consegue desfazer nada.

## `.rpmnew` e `.rpmsave`

Quando uma atualização de pacote traz uma versão nova de um arquivo de configuração que você editou,
as duas famílias fazem coisas diferentes. O Debian **pergunta**, interativamente, mostrando um diff.
O rpm não pergunta: ele escreve o arquivo novo como `config.rpmnew` ao lado do seu, ou — para um
arquivo que o pacote considera seu — move o seu para `config.rpmsave` e instala o novo.

**Então depois de qualquer `dnf upgrade` grande, procure por eles:**

```
find /etc -name '*.rpmnew' -o -name '*.rpmsave'
```

Um `.rpmnew` não revisado é uma mudança de configuração que os empacotadores fizeram e você não está
rodando. É o equivalente silencioso, do lado rpm, de um pacote em `rc`, e é o motivo de um serviço se
comportar de forma diferente em duas máquinas que reportam a mesma versão.
