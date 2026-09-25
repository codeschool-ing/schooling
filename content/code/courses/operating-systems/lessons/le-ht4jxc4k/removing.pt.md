---
title: Removendo sem deixar entulho
version: 1
---

Remover são três comandos, e cada um faz menos do que você talvez espere:

```
ana@server:~$ sudo apt remove -y man-db
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  groff-base libgdbm6t64 libpipeline1 libuchardet0
Use 'sudo apt autoremove' to remove them.
The following packages will be REMOVED:
  man-db
0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
After this operation, 2998 kB disk space will be freed.
(Reading database ... 13821 files and directories currently installed.)
Removing man-db (2.12.0-4build2) ...
ana@server:~$ dpkg -l man-db | tail -1
rc  man-db         2.12.0-4build2 amd64        tools for reading manual pages
ana@server:~$ sudo apt autoremove -y
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  groff-base libgdbm6t64 libpipeline1 libuchardet0
0 upgraded, 0 newly installed, 4 to remove and 0 not upgraded.
After this operation, 4186 kB disk space will be freed.
(Reading database ... 13539 files and directories currently installed.)
Removing groff-base (1.23.0-3build2) ...
Removing libgdbm6t64:amd64 (1.23-5.1build1) ...
Removing libpipeline1:amd64 (1.5.7-2) ...
Removing libuchardet0:amd64 (0.0.8-1build1) ...
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
ana@server:~$ sudo apt purge -y man-db
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages will be REMOVED:
  man-db*
0 upgraded, 0 newly installed, 1 to remove and 0 not upgraded.
After this operation, 0 B of additional disk space will be used.
(Reading database ... 13339 files and directories currently installed.)
Purging configuration files for man-db (2.12.0-4build2) ...
  Removing catpages as well as /var/cache/man hierarchy.
ana@server:~$ dpkg -l man-db 2>&1 | tail -1
dpkg-query: no packages found matching man-db
```

1. O **`apt remove man-db`** removeu o programa e disse, antes, que quatro pacotes **were automatically
   installed and are no longer required**, foram instalados automaticamente e não são mais necessários.
   Ele não os removeu.
2. O **`dpkg -l`** mostrou então `rc`: removido (*removed*), mas os arquivos de **c**onfiguração ficaram.
   O `remove` mantém os ajustes em `/etc`, então uma reinstalação continua de onde parou.
3. O **`apt autoremove`** removeu as quatro dependências de que nada mais precisa, **4186 kB**. Ele
   sabia quais porque o apt as marcou como automáticas ao instalá-las.
4. O **`apt purge`** removeu a configuração também. Depois dele, o dpkg não tem registro nenhum do
   `man-db`.

| comando | remove o programa | remove os ajustes | remove o que ele trouxe |
|---|---|---|---|
| `apt remove` | sim | não | não |
| `apt purge` | sim | sim | não |
| `apt autoremove` | não | não | sim, o que nada mais precisa |

## O registro

Toda ação do apt fica anotada, com quem pediu:

```
ana@server:~$ grep -E '^(Commandline|Requested-By)' /var/log/apt/history.log | tail -4
Commandline: apt autoremove -y
Requested-By: ana (1000)
Commandline: apt purge -y man-db
Requested-By: ana (1000)
ana@server:~$ dpkg -l | grep -c '^ii'
208
```

O `/var/log/apt/history.log` responde "quando isto foi instalado, e por quem?", a pergunta que aparece
quando um servidor começa a se comportar diferente numa terça-feira. O último comando contou **208
pacotes** instalados neste servidor mínimo; um desktop tem bem mais de mil.
