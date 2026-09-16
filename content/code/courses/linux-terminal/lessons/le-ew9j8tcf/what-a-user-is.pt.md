---
title: O que um usuário realmente é
version: 1
---

Um usuário é uma **linha num arquivo de texto**. Não uma pessoa, não uma tela de login, não uma
conta num banco de dados em algum lugar — uma linha, no `/etc/passwd`, com sete campos separados
por dois-pontos.

```
root@vm:~# getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
```

| | campo | aqui |
|---|---|---|
| 1 | **nome** | `ana` |
| 2 | **senha** | `x` — veja abaixo |
| 3 | **UID**, o número que importa | `1001` |
| 4 | **GID primário** | `1002` |
| 5 | **comentário**, historicamente o nome completo | vazio |
| 6 | **diretório pessoal** | `/home/ana` |
| 7 | **shell de login** | `/bin/bash` |

A aula 4 disse que o sistema de arquivos guarda números. **Este arquivo é onde um número ganha um
nome.** Mude o UID do campo 3 e cada arquivo da ana passa a pertencer a outra pessoa — os arquivos
não se moveram, o mapeamento se moveu.

## O campo 2 é um `x`, e esse é o ponto inteiro

Já houve um hash de senha ali, e o `/etc/passwd` precisa ser legível por todos — o `ls -l` precisa
dele para imprimir um nome. Um arquivo de hashes legível pelo mundo é um alvo de quebra offline,
então os hashes se mudaram:

```
root@vm:~# ls -l /etc/passwd /etc/shadow /etc/group
-rw-r--r-- 1 root root    748 Sep 14 22:55 /etc/group
-rw-r--r-- 1 root root   1357 Sep 14 22:45 /etc/passwd
-rw-r----- 1 root shadow  875 Sep 14 22:59 /etc/shadow
```

Leia esses três modos com a aula 4 na mão. O `/etc/passwd` é `644` — qualquer um lê, e precisa
ler. O `/etc/shadow` é `640`, do `root` e do grupo `shadow` — **quem não tem root nem aquele grupo
não lê de jeito nenhum.** O `x` é um ponteiro dizendo *a coisa de verdade está ao lado*.

A seção 03 é sobre o que há ali dentro.

## A maioria das contas não é gente

```
root@vm:~# head -5 /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/usr/sbin/nologin
bin:x:2:2:bin:/bin:/usr/sbin/nologin
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
```

Cinco linhas e uma delas poderia entrar. Um Ubuntu recém-instalado tem umas trinta contas e um
humano.

**Elas existem para que serviços não sejam root.** O servidor web roda como `www-data`, então se
alguém invadi-lo ele fica com o `www-data` — que lê os arquivos do site e pouquíssimo mais. Uma
conta por serviço é uma fronteira, e é a mais barata que o sistema tem.

Ache as pessoas:

```
root@vm:~# awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3, $7}' /etc/passwd
ubuntu 1000 /bin/bash
ana 1001 /bin/bash
bruno 1002 /bin/bash
carla 1003 /bin/bash
```

**UIDs abaixo de 1000 são contas de sistema por convenção**, e toda distribuição segue. `65534` é o
`nobody`, onde a numeração termina.

Ache as que não são:

```
root@vm:~# awk -F: '$7 ~ /nologin|false/ {print $1, $7}' /etc/passwd | head -8
daemon /usr/sbin/nologin
bin /usr/sbin/nologin
sys /usr/sbin/nologin
games /usr/sbin/nologin
man /usr/sbin/nologin
lp /usr/sbin/nologin
mail /usr/sbin/nologin
news /usr/sbin/nologin
```

## O campo 7 é uma decisão, não uma descrição

O shell de login é o que roda quando a conta entra, e o `/usr/sbin/nologin` é um programa de
verdade cuja função inteira é imprimir uma recusa e sair. O `/bin/false` também é, e nem imprime.

**Uma conta com `nologin` continua funcionando.** Ela é dona de arquivos, roda serviços, e o
`sudo -u` executa coisas como ela. O que ela não consegue é um shell, que é exatamente o objetivo.
Quando você cria uma conta para um serviço, este é o campo que importa.

O `/etc/shells` lista o que o sistema considera um shell de login de verdade:

```
root@vm:~# cat /etc/shells
# /etc/shells: valid login shells
/bin/sh
/usr/bin/sh
/bin/bash
/usr/bin/bash
/bin/rbash
/usr/bin/rbash
/usr/bin/dash
/usr/bin/tmux
```

O `nologin` está deliberadamente ausente, e alguns serviços — o `ftp`, por exemplo — recusam uma
conta cujo shell não esteja nessa lista.

## `getent` em vez de `grep`

```
root@vm:~# getent passwd ana
ana:x:1001:1002::/home/ana:/bin/bash
root@vm:~# grep '^ana:' /etc/passwd
ana:x:1001:1002::/home/ana:/bin/bash
```

Saída idêntica, e não são o mesmo comando. **O `grep` lê um arquivo. O `getent` pergunta ao
sistema.** Numa máquina cujas contas vêm de LDAP, Active Directory ou um diretório na nuvem, o
`/etc/passwd` guarda as contas de sistema e mais nada, e o `grep` vai te dizer que um colega real
não existe.

Construa o hábito do `getent` agora, enquanto os dois concordam.

## Duas coisas que decorrem disso tudo

**Um usuário não é uma sessão.** A linha existe esteja ou não alguém logado, e a seção 05 é sobre a
diferença.

**Apagar a linha não apaga os arquivos.** Cada arquivo daquela conta passa a pertencer a um número
sem nome, e a seção 04 mostra exatamente como isso se parece.
