---
title: Achando uma mudança que ninguém anunciou
version: 1
---

Alguém entra no edge1 e muda duas coisas à mão, uma descrição e uma rota estática:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# interface eth2
edge1(config-if)# description guest wifi
edge1(config-if)# exit
edge1(config)# ip route 192.0.2.128/25 198.51.100.1
edge1(config)# end
edge1# exit
Connection to edge1 closed.
```

O backup seguinte percebe, e só o edge1 ganha um commit:

```
ana@ctl:~$ cd net && python backup.py
committed: edge1.conf
ana@ctl:~$ cd net && git -C backups log --oneline
3c44ac7 backup: edge1
4ad37d6 backup: core1, edge1, edge2
```

`git show --stat` dá a data do commit, a noite em que a mudança foi achada, e o arquivo que ele
tocou. A mudança em si é um diff entre o arquivo antes e depois; `git show HEAD~1:edge1.conf`
imprime o arquivo do edge1 como ele estava um commit antes:

```
ana@ctl:~$ cd net && git -C backups show --stat HEAD
commit 3c44ac770f8088930c95197c6cc8a307e0beb760
Author: ana <ana@example.net>
Date:   Thu Oct 1 19:14:13 2026 -0300

    backup: edge1

 edge1.conf | 4 +++-
 1 file changed, 3 insertions(+), 1 deletion(-)
ana@ctl:~$ cd net && diff <(git -C backups show HEAD~1:edge1.conf) backups/edge1.conf
8a9,10
> ip route 192.0.2.128/25 198.51.100.1
> !
16c18
<  description branch LAN
---
>  description guest wifi
```

**Este é o backup como ferramenta de auditoria.** Ninguém precisa lembrar de anunciar uma mudança;
o roteador diz o que roda, e o histórico diz quando isso começou. O que o histórico não consegue
dizer é quem digitou nem por quê; para isso, os logs do próprio roteador, o accounting do servidor
AAA, ou um ticket de mudança como o da aula 7.

A data é a noite em que o backup rodou, não o minuto em que a mudança foi digitada, então um
backup por dia situa uma mudança dentro de um dia. Isso basta para fazer a pergunta certa às
pessoas certas, e é por isso que um job de backup roda pelo menos uma vez por dia.
