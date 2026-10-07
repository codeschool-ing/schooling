---
title: Linux: os arquivos em /var/log
version: 1
---

Numa máquina Ubuntu, a maioria dos logs que um analista lê são **arquivos de texto em `/var/log`**, e o
programa que escreve os principais é o `rsyslog`. Ele não decide o que acontece; decide para onde vai
cada mensagem. As regras dele são curtas o bastante para ler inteiras:

```
root@soc:~# ls -l /var/log/auth.log /var/log/syslog /var/log/kern.log
-rw-r----- 1 syslog adm   0 Oct  7 04:34 /var/log/auth.log
-rw-r----- 1 syslog adm   0 Oct  7 04:34 /var/log/kern.log
-rw-r----- 1 syslog adm 310 Oct  7 04:34 /var/log/syslog
root@soc:~# grep -v '^#' /etc/rsyslog.d/50-default.conf | grep .
auth,authpriv.*			/var/log/auth.log
*.*;auth,authpriv.none		-/var/log/syslog
kern.*				-/var/log/kern.log
mail.*				-/var/log/mail.log
mail.err			/var/log/mail.err
*.emerg				:omusrmsg:*
```

Cada regra tem um **seletor** à esquerda e um destino à direita. Um seletor é `facility.severity`: a
facility diz de que parte do sistema vem a mensagem, e a severidade, quão grave ela é. `auth,authpriv.*`
quer dizer que toda mensagem sobre autenticação, de qualquer severidade, vai para o `auth.log`. A segunda
linha manda todo o resto para o `syslog`, menos autenticação (`.none`), para que a vizinhança das senhas
não se espalhe por um arquivo que mais gente lê. O `-` antes de um caminho diz ao rsyslog para não forçar
a linha para o disco a cada escrita: é mais rápido, e uma queda perde as últimas linhas.

As facilities e as severidades são números fixados pela RFC 5424, e um SIEM as recebe como números:

| severidade | nome | | facility | nome |
|---|---|---|---|---|
| 0 | emerg | | 0 | kern |
| 1 | alert | | 1 | user |
| 2 | crit | | 3 | daemon |
| 3 | err | | 4 | auth |
| 4 | warning | | 10 | authpriv |
| 5 | notice | | 16 a 23 | local0 a local7 |
| 6 | info | | | |
| 7 | debug | | | |

As facilities `local` estão livres para qualquer uso, e é por isso que equipamentos de rede tantas vezes
registram como `local7`.

Agora, um evento de autenticação de verdade. O `su` troca de usuário, e o PAM, a biblioteca que confere
quem você é no Linux, escreve a sessão na facility `authpriv`:

```
root@soc:~# su - ana -c true
root@soc:~# grep pam_unix /var/log/auth.log
2026-10-07T04:34:57.752346-03:00 soc su[9596]: pam_unix(su-l:session): session opened for user ana(uid=30033) by (uid=0)
2026-10-07T04:34:57.762003-03:00 soc su[9596]: pam_unix(su-l:session): session closed for user ana
```

O carimbo de hora é **RFC 3339 com microssegundos e o deslocamento**, `-03:00`, que é o padrão do Ubuntu
24.04 e o formato que vale pedir em toda parte. Depois vêm o host, `soc`; o programa e o número do
processo, `su[9596]`; e a mensagem. Repare nas permissões da listagem acima: `syslog adm`, modo
`rw-r-----`. **Só o root e o grupo `adm` leem esses arquivos**, então um usuário fora do `adm` é recusado
até na linha que ele mesmo causou:

```
ana@soc:~$ logger -t backup 'nightly copy finished: 412 files'
ana@soc:~$ tail -n 1 /var/log/syslog
tail: cannot open '/var/log/syslog' for reading: Permission denied
root@soc:~# tail -n 1 /var/log/syslog
2026-10-07T04:34:57.776265-03:00 soc backup: nightly copy finished: 412 files
```

O `logger` é como um script escreve no syslog; com `-t` ele dá o próprio nome, e a linha cai no `syslog`
porque a facility padrão é `user`. O Ubuntu põe no `adm` a primeira conta criada na instalação; todos os
outros são recusados, o que é o correto para um arquivo que registra quem entrou e de onde.

Mais alguns lugares em `/var/log` importam numa investigação:

| arquivo | o que guarda | como ler |
|---|---|---|
| `auth.log` | logins, `sudo`, `su`, SSH, PAM | texto |
| `syslog` | tudo o que não foi encaminhado a outro lugar | texto |
| `kern.log` | o kernel: dispositivos, linhas de firewall registradas pelo kernel | texto |
| `apt/history.log`, `dpkg.log` | software instalado e removido, com datas | texto |
| `wtmp`, `btmp`, `lastlog` | logins bem-sucedidos, logins falhos, último login de cada usuário | binário: `last`, `lastb`, `lastlog` |
| `audit/audit.log` | a trilha de auditoria do kernel, quando o `auditd` está instalado | `ausearch` |
| `journal/` | o journal do systemd | `journalctl`, na próxima seção |
