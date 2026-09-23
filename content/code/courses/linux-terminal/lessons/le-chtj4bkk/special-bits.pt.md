---
title: setuid, setgid e o sticky bit
version: 2
---

Mais três bits, um quarto dígito octal, e cada um existe porque os nove caracteres não conseguiam
expressar algo de que o sistema realmente precisava.

```
root@vm:~# stat -c '%a %A %n' /usr/bin/passwd /tmp /srv/team
4755 -rwsr-xr-x /usr/bin/passwd
1777 drwxrwxrwt /tmp
2775 drwxrwsr-x /srv/team
```

Três coisas reais desta máquina, uma para cada bit.

| | valor | num arquivo | num diretório |
|---|---|---|---|
| **setuid** | 4 | roda como o **dono** do arquivo | (nada, no Linux) |
| **setgid** | 2 | roda como o **grupo** do arquivo | entradas novas herdam o **grupo** |
| **sticky** | 1 | (nada, no Linux) | você remove **apenas as suas** entradas |

E eles são mostrados substituindo um `x`, e é por isso que é preciso olhar duas vezes:

| vaga | com `x` | sem `x` |
|---|---|---|
| x do dono | `s` — setuid | `S` |
| x do grupo | `s` — setgid | `S` |
| x de outros | `t` — sticky | `T` |

**Uma maiúscula quer dizer que o bit especial está ligado e a execução não**, o que é quase sempre
um engano — um programa setuid que ninguém pode executar não faz nada.

## setuid: o `passwd` é a razão de ele existir

```
-rwsr-xr-x 1 root root 64152 May 30  2024 /usr/bin/passwd
```

Trocar sua senha é escrever no `/etc/shadow`, que é `-rw-------` e pertence ao root. Você não pode
escrever nele. E, ainda assim, você troca a própria senha, sem root, sem pedir a ninguém.

**O `s` é como.** Quando você roda o `passwd`, o processo roda **como root** — como o dono do
arquivo — e não como você. Ele faz a única coisa estreita para a qual existe, confere que a conta
que você está alterando é a sua, e termina.

Esse é um buraco deliberado e auditado no modelo, e existem pouquíssimos deles. Ache:

```
find /usr/bin -perm -4000 -ls
```

Numa máquina normal essa lista é curta — `passwd`, `sudo`, `su`, `mount`, o `ping` em sistemas mais
antigos — e cada entrada é um programa escrito sabendo que rodaria como root.

**Nunca ligue isso em algo que você escreveu.** Um script setuid é a vulnerabilidade clássica, e o
Linux ignora o bit em scripts exatamente por isso; um binário setuid que recebe um nome de arquivo
de você e o abre é um jeito de ler qualquer coisa da máquina. Se você se pegar indo atrás de setuid,
a resposta que você quer é quase certamente `sudo` com uma regra estreita — seção 11.

## setgid num diretório: o que você vai usar de verdade

```
root@vm:~# ls -ld /srv/team
drwxrwsr-x 2 root team 4096 Sep 14 22:44 /srv/team
```

O `s` está na vaga do grupo, e num diretório quer dizer: **tudo que for criado aqui dentro pertence
ao grupo deste diretório**, quem quer que tenha criado.

Veja acontecer. O grupo primário do bruno é `bruno`, e a umask dele é a comum, `022`:

```
bruno@vm:/srv/team$ umask
0022
bruno@vm:/srv/team$ touch fresh.md
bruno@vm:/srv/team$ ls -l fresh.md
-rw-r--r-- 1 bruno team 0 Sep 14 22:46 fresh.md
bruno@vm:/srv/team$ id -gn
bruno
```

**O grupo do arquivo é `team`, e o grupo primário do bruno é `bruno`.** Sem o bit setgid teria sido
`bruno`, e a ana — que está em `team` e não em `bruno` — ficaria de fora de um arquivo num diretório
feito para compartilhar.

Essa é a receita inteira de um diretório compartilhado, e vale guardar:

```
sudo chgrp team /srv/team
sudo chmod 2775 /srv/team
umask 002
```

Grupo, o bit setgid para os arquivos novos herdarem, e uma umask que não tira o `w` do grupo —
porque o setgid define o *grupo* e a umask continua decidindo os *bits*. Erre um dos três e o
diretório funciona pela metade, que é o tipo confuso de quebrado.

Ele também é herdado: um subdiretório criado dentro de um diretório setgid é setgid também, então a
árvore inteira mantém o comportamento sem ninguém manter nada.

## O sticky bit: por que o `/tmp` não é um desastre

O `/tmp` é `1777` — **qualquer um escreve nele**. A seção 06 disse que um diretório em que você
escreve é um diretório cujos arquivos você apaga, sejam de quem forem. No `/tmp` isso significaria
que qualquer um apagaria o trabalho de qualquer um.

```
ana@vm:~$ printf 'anas file\n' > /tmp/anas.txt
ana@vm:~$ ls -l /tmp/anas.txt
-rw-r--r-- 1 ana ana 10 Sep 14 22:45 /tmp/anas.txt
```

```
bruno@vm:~$ ls -ld /tmp
drwxrwxrwt 38 root root 36864 Sep 14 22:45 /tmp
bruno@vm:~$ cat /tmp/anas.txt
anas file
bruno@vm:~$ rm /tmp/anas.txt
rm: cannot remove '/tmp/anas.txt': Operation not permitted
```

O bruno tem `w` no `/tmp`. Ele pode criar arquivos ali e apagar os dele. **O `t` restringe a
remoção ao dono da entrada** — e ao dono do diretório, e ao root.

Chama-se *sticky* por uma razão histórica que não vale mais: no Unix antigo ele mantinha a imagem de
um programa no swap. O nome sobreviveu ao recurso.

Você vai encontrá-lo no `/tmp`, no `/var/tmp`, e em qualquer diretório que alguém tenha deixado
gravável por todos de propósito. **Se você algum dia criar um diretório gravável por todos,
ligue.** `chmod 1777` em vez de `chmod 777`, e a diferença é a segurança inteira.

## Como ligar

```
chmod u+s file          # setuid
chmod g+s directory     # setgid
chmod +t directory      # sticky
chmod 2775 directory    # the same as g+s on 775
```

E a armadilha da seção 04, repetida porque é a que morde: **`chmod 755` num arquivo `4755` limpa o
bit setuid.** Um número de três dígitos põe o quarto dígito em zero. Use a forma simbólica quando a
intenção é mudar só os nove.

## O que fazer quando você encontra um

Um binário setuid inesperado, num lugar que pacote nenhum reivindica, merece ser levado a sério — é
assim que um comprometimento persiste. `find / -perm -4000 -type f 2>/dev/null` lista todos, e
`dpkg -S` ou `rpm -qf` diz a que pacote cada um pertence. O que não pertence a pacote nenhum é o que
se pergunta a respeito.
