---
title: Uma tarefa agendada, escrita do zero
version: 1
---

O backup noturno precisa de três coisas: **um script** que faz o trabalho, **um serviço** que roda o
script, e **um timer** que inicia o serviço. O script, `/usr/local/bin/office-backup`, compacta o
`/etc/apt` em `/var/backups`. Os outros dois são arquivos de texto curtos:

```
ana@server:~$ cat /etc/systemd/system/office-backup.service
[Unit]
Description=Copy /etc/apt to /var/backups

[Service]
Type=oneshot
ExecStart=/usr/local/bin/office-backup
ana@server:~$ cat /etc/systemd/system/office-backup.timer
[Unit]
Description=Run office-backup every weekday at 02:00

[Timer]
OnCalendar=Mon..Fri 02:00
Persistent=true

[Install]
WantedBy=timers.target
```

- O **serviço** é `Type=oneshot`: roda, termina e para, em vez de ficar de pé como o cron.
- O **timer** tem o mesmo nome, e é assim que ele sabe qual serviço iniciar. O
  **`OnCalendar=Mon..Fri 02:00`** é todo dia útil às duas. O **`Persistent=true`** quer dizer que, se o
  servidor estava desligado às duas, o backup roda assim que ele voltar, em vez de ser pulado.
- O **`WantedBy=timers.target`** é onde o `enable` engata o timer, para ele ficar armado a cada boot.

```
ana@server:~$ sudo systemctl daemon-reload
ana@server:~$ sudo systemctl enable --now office-backup.timer
Created symlink /etc/systemd/system/timers.target.wants/office-backup.timer → /etc/systemd/system/office-backup.timer.
ana@server:~$ systemctl list-timers office-backup.timer --no-pager
NEXT                          LEFT LAST                        PASSED UNIT                ACTIVATES
Sun 2026-09-27 23:00:00 -03 2 days Fri 2026-09-25 11:20:56 -03      - office-backup.timer office-backup.service

1 timers listed.
Pass --all to see loaded but inactive timers, too.
ana@server:~$ sudo systemctl start office-backup.service
ana@server:~$ sudo journalctl -u office-backup.service --no-pager -o cat | tail -3
backup written: /var/backups/etc-apt.tar.gz
office-backup.service: Deactivated successfully.
Finished office-backup.service - Copy /etc/apt to /var/backups.
ana@server:~$ ls -lh /var/backups/etc-apt.tar.gz
-rw-r--r-- 1 root root 3.6K Sep 25 11:24 /var/backups/etc-apt.tar.gz
```

1. O **`daemon-reload`** avisa o systemd para ler os arquivos novos. Esquecê-lo é o motivo de sempre de
   uma unidade "não existir" logo depois de escrita.
2. O **`enable --now`** armou o timer agora e a cada boot; o `enable` imprimiu o link que criou.
3. O **`list-timers`** mostra quando ele roda da próxima vez.
4. O **`start office-backup.service`** rodou o backup **agora**, sem esperar o timer. É assim que se
   testa uma tarefa agendada, e ela deve ser testada antes de alguém confiar nela.
5. O journal guardou a saída do script, **`backup written`**, e o arquivo está lá.

**Olhe a coluna NEXT.** Ela diz domingo às 23:00, não segunda às 02:00. Este registro imprime os
horários de São Paulo, e o fuso do próprio relógio do servidor é **UTC**, como o `timedatectl` da aula 3
mostrou: 02:00 UTC de segunda são 23:00 de domingo em São Paulo. Um backup que deveria rodar com o
escritório dormindo rodaria com alguém ainda trabalhando até tarde. **Defina o fuso de um servidor ao
instalá-lo**, `sudo timedatectl set-timezone America/Sao_Paulo`, ou escreva todo agendamento em UTC de
propósito.
