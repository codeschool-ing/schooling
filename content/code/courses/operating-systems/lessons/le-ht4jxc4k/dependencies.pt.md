---
title: Dependências: pedir um, receber cinco
version: 1
---

A maioria dos programas é construída sobre outros. A aula 8 descobriu que o leitor de manuais não estava
neste servidor; instalá-lo mostra para que serve um gerenciador de pacotes:

```
ana@server:~$ sudo apt install -y man-db
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following additional packages will be installed:
  groff-base libgdbm6t64 libpipeline1 libuchardet0
Suggested packages:
  groff gdbm-l10n apparmor www-browser
The following NEW packages will be installed:
  groff-base libgdbm6t64 libpipeline1 libuchardet0 man-db
0 upgraded, 5 newly installed, 0 to remove and 0 not upgraded.
Need to get 2390 kB of archives.
After this operation, 7184 kB of additional disk space will be used.
Get:1 http://archive.ubuntu.com/ubuntu noble/main amd64 libuchardet0 amd64 0.0.8-1build1 [75.3 kB]
Get:2 http://archive.ubuntu.com/ubuntu noble/main amd64 groff-base amd64 1.23.0-3build2 [1020 kB]
Get:3 http://archive.ubuntu.com/ubuntu noble/main amd64 libgdbm6t64 amd64 1.23-5.1build1 [34.4 kB]
Get:4 http://archive.ubuntu.com/ubuntu noble/main amd64 libpipeline1 amd64 1.5.7-2 [23.6 kB]
Get:5 http://archive.ubuntu.com/ubuntu noble/main amd64 man-db amd64 2.12.0-4build2 [1237 kB]
Fetched 2390 kB in 2s (1260 kB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package libuchardet0:amd64.
(Reading database ... 13332 files and directories currently installed.)
Preparing to unpack .../libuchardet0_0.0.8-1build1_amd64.deb ...
Unpacking libuchardet0:amd64 (0.0.8-1build1) ...
Selecting previously unselected package groff-base.
Preparing to unpack .../groff-base_1.23.0-3build2_amd64.deb ...
Unpacking groff-base (1.23.0-3build2) ...
Selecting previously unselected package libgdbm6t64:amd64.
Preparing to unpack .../libgdbm6t64_1.23-5.1build1_amd64.deb ...
Unpacking libgdbm6t64:amd64 (1.23-5.1build1) ...
Selecting previously unselected package libpipeline1:amd64.
Preparing to unpack .../libpipeline1_1.5.7-2_amd64.deb ...
Unpacking libpipeline1:amd64 (1.5.7-2) ...
Selecting previously unselected package man-db.
Preparing to unpack .../man-db_2.12.0-4build2_amd64.deb ...
Unpacking man-db (2.12.0-4build2) ...
Setting up libpipeline1:amd64 (1.5.7-2) ...
Setting up libgdbm6t64:amd64 (1.23-5.1build1) ...
Setting up libuchardet0:amd64 (0.0.8-1build1) ...
Setting up groff-base (1.23.0-3build2) ...
Setting up man-db (2.12.0-4build2) ...
Building database of manual pages ...
Created symlink /etc/systemd/system/timers.target.wants/man-db.timer → /usr/lib/systemd/system/man-db.timer.
man-db.service is a disabled or a static unit, not starting it.
Processing triggers for libc-bin (2.39-0ubuntu8.9) ...
ana@server:~$ man -f ls
ls (1)               - list directory contents
```

O `man-db` precisa de outros quatro pacotes, e o apt os listou antes de fazer qualquer coisa: **the
following additional packages will be installed**, os pacotes adicionais a seguir serão instalados.
Depois baixou os cinco, **2390 kB**, desempacotou numa ordem que funciona, e configurou. A última linha
prova: o `man -f ls` responde, onde o `man` da aula 8 nem existia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Uma árvore de dependências. O man-db, o pacote pedido, precisa de outros quatro: groff-base, libpipeline1, libuchardet0 e libgdbm6t64. O apt os instalou automaticamente e os marcou como automáticos, que é como o autoremove sabe depois que eles podem ir embora quando nada mais precisar deles.\"><defs><marker id=\"dp-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"290\" y=\"20\" width=\"140\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">man-db</text><text x=\"440\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o que se pediu</text><path d=\"M360 54 L122 96\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><rect x=\"60\" y=\"98\" width=\"124\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"122\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">groff-base</text><path d=\"M360 54 L282 96\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><rect x=\"220\" y=\"98\" width=\"124\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"282\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libpipeline1</text><path d=\"M360 54 L442 96\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><rect x=\"380\" y=\"98\" width=\"124\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"442\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libuchardet0</text><path d=\"M360 54 L602 96\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#dp-ah)\"></path><rect x=\"540\" y=\"98\" width=\"124\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"602\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">libgdbm6t64</text><text x=\"20\" y=\"152\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">instalados automaticamente, e marcados assim</text></svg>", "caption": "Peça um pacote, receba cinco. Os quatro que o apt escolheu sozinho levam uma marca, e essa marca é o que o autoremove lê quando o que você pediu não está mais lá."}
```

Duas linhas dessa saída valem ser lidas sempre:

- **Suggested packages** são extras que o apt *não* instala. Ele está avisando que existem.
- **After this operation, 7184 kB of additional disk space will be used.** Num disco pequeno, essa é a
  linha a ler antes de dizer sim.

## No Windows e no macOS

Um instalador de um site carrega as próprias cópias de tudo o que precisa, e é por isso que dois
programas podem instalar cada um a sua cópia da mesma biblioteca, e por que remover um nunca remove a do
outro. Gerenciadores de pacotes compartilham uma cópia e mantêm a conta, que é do que a próxima seção
depende.
