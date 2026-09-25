---
title: O que está rodando em segundo plano
version: 1
---

A aula 1 deixou o `systemd` como primeiro processo, o PID 1, e disse que ele inicia todo o resto. O
**`systemctl`** é como se conversa com ele. Os serviços são as **unidades** dele do tipo `.service`:

```
ana@server:~$ systemctl list-units --type=service --state=running --no-pager --no-legend
  cron.service             loaded active running Regular background program processing daemon
  dbus.service             loaded active running D-Bus System Message Bus
  systemd-journald.service loaded active running Journal Service
  systemd-logind.service   loaded active running User Login Management
  systemd-resolved.service loaded active running Network Name Resolution
  user@1000.service        loaded active running User Manager for UID 1000
ana@server:~$ sudo systemctl status cron --no-pager -n 0
● cron.service - Regular background program processing daemon
     Loaded: loaded (/usr/lib/systemd/system/cron.service; enabled; preset: enabled)
     Active: active (running) since Fri 2026-09-25 11:20:56 -03; 3min 12s ago
       Docs: man:cron(8)
   Main PID: 5701 (cron)
     CGroup: /system.slice/cron.service
             └─5701 /usr/sbin/cron -f -P
```

Seis serviços neste servidor mínimo, cada um com uma descrição de uma linha: o `cron`, o agendador
clássico da seção 05; o `dbus`, como os programas conversam entre si; o journal, que junta todo log; os
logins; a resolução de nomes; e um gerenciador da sessão da própria ana.

O `systemctl status` dá o quadro completo de um serviço: **Loaded**, que arquivo o define e se ele está
**habilitado**; **Active**, se roda agora e desde quando; e o **Main PID**, o processo que você veria no
`ps`. O `-n 0` deixou de fora as linhas de log que o `status` normalmente acrescenta no fim; a seção 04
lê o log de um serviço de propósito.

Um desktop roda dezenas de serviços, e cada um é um programa que inicia sem ninguém pedir. A pergunta
para cada um é a mesma do software instalado da aula 11: **alguém está usando?**
