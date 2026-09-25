---
title: Achando e instalando com o apt
version: 1
---

O servidor não tem o `tree`, um programinha que desenha pastas como uma árvore:

```
ana@server:~$ tree
bash: tree: command not found
```

**Ache antes, e leia o que ele é antes de instalar:**

```
ana@server:~$ apt search --names-only '^tree$'
Sorting... Done
Full Text Search... Done
tree/noble-updates 2.1.1-2ubuntu3.24.04.2 amd64
  displays an indented directory tree, in color

ana@server:~$ apt-cache show tree | grep -E '^(Package|Version|Section|Installed-Size|Depends|Description-en)'
Package: tree
Section: universe/utils
Installed-Size: 108
Version: 2.1.1-2ubuntu3.24.04.2
Depends: libc6 (>= 2.38)
Description-en: displays an indented directory tree, in color
Package: tree
Version: 2.1.1-2ubuntu3
Section: universe/utils
Installed-Size: 108
Depends: libc6 (>= 2.38)
Description-en: displays an indented directory tree, in color
```

O `apt search` achou um pacote com exatamente esse nome. O `apt-cache show` imprimiu o registro de
**duas versões**: a do `noble-updates`, a mais nova, e a que veio com a versão do Ubuntu. A seção dele,
`universe/utils`, é o ponto da aula 6 sobre quem o mantém; ele só precisa da `libc6`, que todo sistema
tem.

```
ana@server:~$ sudo apt install -y tree
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  tree
0 upgraded, 1 newly installed, 0 to remove and 0 not upgraded.
Need to get 47.4 kB of archives.
After this operation, 111 kB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu noble-updates/universe amd64 tree amd64 2.1.1-2ubuntu3.24.04.2 [47.4 kB]
Fetched 47.4 kB in 0s (242 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package tree.
(Reading database ... 13325 files and directories currently installed.)
Preparing to unpack .../tree_2.1.1-2ubuntu3.24.04.2_amd64.deb ...
Unpacking tree (2.1.1-2ubuntu3.24.04.2) ...
Setting up tree (2.1.1-2ubuntu3.24.04.2) ...
ana@server:~$ which tree
/usr/bin/tree
ana@server:~$ dpkg -L tree | grep bin/
/usr/bin/tree
ana@server:~$ tree -L 1 /etc/apt
/etc/apt
├── apt.conf.d
├── auth.conf.d
├── keyrings
├── preferences.d
├── sources.list.d
└── trusted.gpg.d

7 directories, 0 files
```

O que a instalação disse, em ordem: o que vai instalar, quanto baixa (*47.4 kB*) e quanto ocupa em
disco (*111 kB*), de onde veio (`noble-updates/universe`), e os passos que o dpkg faz por baixo,
*desempacotar* e *configurar*. O `apt` é a frente amigável; o **`dpkg`** é a ferramenta que de fato
põe os arquivos no disco e guarda o registro deles.

O `dpkg -L` lista **todo arquivo que um pacote instalou**, que é como você descobre onde um programa pôs
as partes dele. Aqui há um programa, `/usr/bin/tree`, o mesmo caminho que o `which` achou.
