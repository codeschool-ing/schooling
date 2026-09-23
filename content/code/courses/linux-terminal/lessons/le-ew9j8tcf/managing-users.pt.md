---
title: Criar, alterar e remover uma conta
version: 2
---

Existem dois comandos para criar um usuário e eles não são a mesma ferramenta.

| | é | comportamento |
|---|---|---|
| `useradd` | o de baixo nível, em todo Linux | faz exatamente o que você pede, e nada além |
| `adduser` | um script Perl, só no Debian e no Ubuntu | faz perguntas, cria a casa, define a senha |

**Use `adduser` na mão e `useradd` em script**, porque o primeiro é amigável e o segundo é
previsível. O Red Hat não tem um `adduser` digno do nome — lá ele é um link simbólico para o
`useradd`, e scripts que supõem o contrário quebram ao mudar de casa.

## O `useradd` faz o mínimo, e o mínimo surpreende

```
root@vm:~# useradd dora
root@vm:~# getent passwd dora
dora:x:1005:1008::/home/dora:/bin/sh
root@vm:~# ls -ld /home/dora
ls: cannot access '/home/dora': No such file or directory
```

Leia com atenção. A conta existe. A casa dela está registrada como `/home/dora`. **E `/home/dora`
não existe.** O shell é `/bin/sh` em vez de bash, porque ninguém disse o contrário.

O `useradd` criou uma linha. Ele não criou mais nada, e não te avisou.

Uma conta cuja casa não existe ainda entra, e cai em `/` com um erro — uma das primeiras
experiências mais confusas que se pode dar a alguém. Diga o que você quer:

```
root@vm:~# useradd -m -s /bin/bash -c 'Dora Silva' dora
root@vm:~# getent passwd dora
dora:x:1005:1008:Dora Silva:/home/dora:/bin/bash
root@vm:~# ls -la /home/dora
total 20
drwxr-x---  2 dora dora 4096 Sep 14 23:22 .
drwxr-xr-x 10 root root 4096 Sep 14 23:22 ..
-rw-r--r--  1 dora dora  220 Mar 31  2024 .bash_logout
-rw-r--r--  1 dora dora 3771 Mar 31  2024 .bashrc
-rw-r--r--  1 dora dora  807 Mar 31  2024 .profile
```

| | |
|---|---|
| `-m` | criar o diretório pessoal |
| `-s` | shell de login — o campo 7 da seção 02 |
| `-c` | o campo de comentário, historicamente o nome completo |
| `-G` | grupos suplementares já na criação |
| `-u` | um UID específico, quando ele precisa casar com outra máquina |
| `-r` | uma conta de **sistema**: UID abaixo de 1000, sem casa |

## De onde vieram aqueles três dotfiles

```
root@vm:~# ls -la /etc/skel
total 20
drwxr-xr-x  2 root root 4096 Feb 17  2026 .
drwxr-xr-x 75 root root 4096 Sep 14 23:22 ..
-rw-r--r--  1 root root  220 Mar 31  2024 .bash_logout
-rw-r--r--  1 root root 3771 Mar 31  2024 .bashrc
-rw-r--r--  1 root root  807 Mar 31  2024 .profile
```

**O `/etc/skel` é o esqueleto**, e o `-m` copia ele para dentro da casa nova. Qualquer coisa que
você puser ali aparece em toda conta criada depois — um `.bashrc` da empresa, um editor padrão, um
README. Repare que o `ls` sem `-a` mostra como vazio, que é o ponto da aula 3 seção 14 fazendo o
trabalho dele.

Ele não se aplica retroativamente. Contas que já existem ficam com o que têm.

## O `usermod` altera um campo por vez

```
root@vm:~# usermod -aG team dora
root@vm:~# id dora
uid=1005(dora) gid=1008(dora) groups=1008(dora),1004(team)
root@vm:~# usermod -s /usr/sbin/nologin dora
root@vm:~# getent passwd dora
dora:x:1005:1008:Dora Silva:/home/dora:/usr/sbin/nologin
```

As flags espelham as do `useradd`, mais algumas próprias:

| | |
|---|---|
| `-aG` | **acrescenta** aos grupos suplementares — a seção 08 da aula 4 diz por que o `-a` importa |
| `-s` | troca o shell |
| `-L` / `-U` | trava / destrava, igual ao `passwd -l` |
| `-e 2026-12-31` | expira a conta numa data |
| `-d /nova/casa -m` | move o diretório pessoal e atualiza o registro |

**O `-l` renomeia a conta, e só a conta:**

```
root@vm:~# usermod -l dorasilva dora
root@vm:~# getent passwd dorasilva
dorasilva:x:1005:1008:Dora Silva:/home/dora:/usr/sbin/nologin
root@vm:~# ls -ld /home/dora
drwxr-x--- 2 dorasilva dora 4096 Sep 14 23:22 /home/dora
```

O nome mudou. **A casa continua sendo `/home/dora`**, e o registro que aponta para ela também. Os
arquivos continuam dela porque sempre foram do uid `1005` — o ponto da seção 07 da aula 4, chegando
pelo outro lado. Renomear uma pessoa é `usermod -l nomenovo -d /home/nomenovo -m nomeantigo`, e as
peças são separadas porque podem ser.

## O `userdel`, e o diretório que ele deixa para trás

```
root@vm:~# userdel dorasilva
root@vm:~# getent passwd dorasilva
root@vm:~# ls -ld /home/dora
drwxr-x--- 2 1005 dora 4096 Sep 14 23:22 /home/dora
```

A conta se foi — o `getent` não imprime nada. **O diretório pessoal continua lá, e o `ls` agora
imprime `1005` onde havia um nome**, porque não sobrou nada para consultar o número.

Essa é a demonstração mais visível da afirmação da seção 02 de que o sistema de arquivos guarda
números. Nada naqueles arquivos mudou. O mapeamento mudou.

O `userdel -r` remove a casa e a caixa de correio também — e **vale não fazer por reflexo.** A
sequência de sempre quando alguém sai é:

1. travar a conta, para ninguém entrar como ela: `usermod -L -e 1 nome`;
2. remover as chaves ssh dela, porque a seção 06 explica por que travar não basta;
3. descobrir o que ela possuía: `find / -uid 1005 2>/dev/null`;
4. entregar aqueles arquivos a alguém, ou arquivá-los;
5. **depois** apagar a conta.

Apagar primeiro deixa arquivos órfãos pertencentes a um número — e a próxima conta criada recebe o
próximo UID livre, que numa máquina pequena é frequentemente o que você acabou de liberar. Arquivos
de quem saiu passam a pertencer a quem chegou, em silêncio.

## Grupos, rapidamente

```
groupadd deploy              # make one
groupdel deploy              # remove it
gpasswd -a bruno deploy      # add somebody
gpasswd -d bruno deploy      # remove somebody
```

O `gpasswd -a` é o `usermod -aG` sem o jeito de errar. E o aviso da seção 08 da aula 4 vale para
tudo isso: **a mudança não alcança um shell que já está aberto.**

## O que fazer numa máquina com mais do que um punhado de pessoas

Nada nesta seção escala além de umas vinte contas numa máquina. Passando disso, as contas vêm de um
diretório — LDAP, Active Directory, um provedor de identidade na nuvem — e o `useradd` na máquina é
o lugar errado de olhar.

O sinal é o `getent passwd` devolvendo alguém que não está no `/etc/passwd`. A seção 02 mandou
construir esse hábito exatamente para este momento.
