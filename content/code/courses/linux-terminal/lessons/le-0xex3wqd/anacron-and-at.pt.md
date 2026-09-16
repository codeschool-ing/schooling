---
title: A máquina que estava desligada, e o job que roda uma vez
version: 1
---

O cron tem uma suposição: **a máquina está ligada.** Um job agendado para 03:00
num laptop que está fechado às 03:00 não roda atrasado — ele não roda.

## O anacron

```
ana@vm:~$ cat /etc/anacrontab
# /etc/anacrontab: configuration file for anacron

# See anacron(8) and anacrontab(5) for details.

SHELL=/bin/sh
HOME=/root
LOGNAME=root

# These replace cron's entries
1       5       cron.daily      run-parts --report /etc/cron.daily
7       10      cron.weekly     run-parts --report /etc/cron.weekly
@monthly        15      cron.monthly    run-parts --report /etc/cron.monthly
```

**Quatro campos, e nenhum deles é uma hora do relógio:**

| | |
|---|---|
| `1` | o período, em dias |
| `5` | o atraso em minutos depois que o anacron inicia |
| `cron.daily` | o **identificador do job**, que também é um nome de arquivo |
| `run-parts …` | o comando |

O anacron não pergunta que horas são. Ele pergunta **há quanto tempo este job
rodou pela última vez**, e a resposta é um arquivo:

```
/var/spool/anacron/cron.daily        # one line: the date it last ran
```

Duas execuções de um anacrontab privado, com um minuto de diferença, dizem a
coisa inteira:

```
ana@vm:~/work/cron$ cat myanacrontab
SHELL=/bin/sh
1       0       daily-report    echo "report for $(date +\%F)"
7       0       weekly-report   echo "weekly report"
ana@vm:~/work/cron$ anacron -T -t myanacrontab && echo "syntax ok"
syntax ok
ana@vm:~/work/cron$ anacron -d -n -t myanacrontab -S spool
Anacron 2.3 started on 2026-09-15
Will run job `daily-report'
Will run job `weekly-report'
Jobs will be executed sequentially
Job `daily-report' started
Job `daily-report' terminated (mailing output)
Job `weekly-report' started
Job `weekly-report' terminated (mailing output)
Normal exit (2 jobs run)
ana@vm:~/work/cron$ ls -l spool; cat spool/daily-report
total 8
-rw------- 1 ana ana 9 Sep 15 12:31 daily-report
-rw------- 1 ana ana 9 Sep 15 12:31 weekly-report
20260915
ana@vm:~/work/cron$ anacron -d -n -t myanacrontab -S spool
Anacron 2.3 started on 2026-09-15
Normal exit (0 jobs run)
```

**A primeira execução faz os dois jobs e escreve a data. A segunda não faz nada**
— `Normal exit (0 jobs run)` — porque os dois já rodaram hoje. Aquele arquivo,
`20260915`, é a memória inteira do anacron.

| | |
|---|---|
| `-T` | confere a sintaxe do anacrontab e sai |
| `-t arquivo` | usa este anacrontab em vez do `/etc/anacrontab` |
| `-S dir` | usa este diretório de spool |
| `-d` | fica em primeiro plano e diz o que está fazendo |
| `-n` | roda os jobs devidos **agora**, ignorando os campos de atraso |
| `-f` | força: roda mesmo que já tenham rodado hoje |

**O `anacron -T` é o `visudo` do agendamento** — é a conferência que você pode
rodar antes de o arquivo estar valendo, e não há equivalente para um crontab
tirando a do `crontab -e`.

## Como ele se encaixa com o cron

Olhe de novo o crontab do sistema da seção 05:

```sh
25 6 * * * root test -x /usr/sbin/anacron || { cd / && run-parts --report /etc/cron.daily; }
```

**`test -x /usr/sbin/anacron ||`** — se o anacron estiver instalado, o cron *não*
roda os jobs diários, porque o anacron vai rodar. E o próprio anacron é iniciado
pelo `/etc/cron.d/anacron`, e por um timer do systemd, e em alguns sistemas no
boot.

O resultado é o que você quer num laptop e é confuso na primeira leitura: o
`/etc/cron.daily` roda **uma vez por dia, em algum momento depois de a máquina
estar acordada**, em vez de às 06:25.

| | |
|---|---|
| servidor, sempre ligado | cron. O anacron não acrescenta nada |
| laptop, desktop, qualquer coisa que se desliga | anacron, ou um timer do systemd com `Persistent=true` |
| um job cujo *horário* importa | cron ou `OnCalendar` — o anacron não promete um |

**A granularidade do anacron é um dia.** Nada de hora em hora, nada num minuto
específico. O `Persistent=true` da seção 12 é a mesma ideia com um relógio
junto, que é por que o anacron importa menos numa máquina com systemd do que
importava.

## O `at`, que roda uma vez

```
ana@vm:~/work/cron$ cat at.log
12:35:00
ana@vm:~/work/cron$ atq
ana@vm:~/work/cron$ echo "atq printed nothing: the queue is empty"
atq printed nothing: the queue is empty
```

Aquilo é o resultado de `echo "date +%T >> at.log" | at now + 1 minute`, um
minuto depois: **rodou às 12:35:00 exatamente, e então sumiu.** Um job do `at` é
consumido ao rodar.

```
ana@vm:~/work/cron$ at 03:00 tomorrow <<< "/home/ana/bin/report.sh"
warning: commands will be executed using /bin/sh
job 2 at Wed Sep 16 03:00:00 2026
ana@vm:~/work/cron$ atq
2       Wed Sep 16 03:00:00 2026 a ana
ana@vm:~/work/cron$ atrm $(atq | cut -f1); atq; echo "removed, exit $?"
removed, exit 0
```

| | |
|---|---|
| `at 03:00 tomorrow` | lê os comandos da entrada padrão |
| `at -f script.sh 03:00` | ou de um arquivo |
| `atq` | o que está na fila |
| `atrm 2` | cancela o job 2 |
| `at -c 2` | imprime o job inteiro, ambiente incluído |
| `batch` | roda quando a máquina estiver ociosa o bastante — um limite de carga com que o `atd` foi iniciado |

**`warning: commands will be executed using /bin/sh`** é o `at` te dizendo o que a
seção 06 disse: o mesmo `/bin/sh`, o mesmo profile ausente.

Mas o `at` faz uma coisa que o cron não faz: ele **captura o seu ambiente atual**
e o repete. O `at -c` imprime o job que ele vai rodar, e o topo dele é o seu
shell:

```
ana@vm:~$ at -c 3 | head -10
#!/bin/sh
# atrun uid=1001 gid=1002
# mail ana 0
umask 2
NVM_RC_VERSION=; export NVM_RC_VERSION
JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64; export JAVA_HOME
GRADLE_HOME=/opt/gradle; export GRADLE_HOME
RBENV_SHELL=bash; export RBENV_SHELL
PWD=/home/ana; export PWD
LOGNAME=ana; export LOGNAME
```

**Isso é mais amigável e não é mais confiável.** O job roda com o que por acaso
estava definido no terminal em que você o digitou — incluindo um `JAVA_HOME` de
uma sessão de que você já esqueceu — que não é uma coisa que você escolheu e não é
uma coisa que outra pessoa consegue reproduzir.

**Use para "rode isto às quatro, uma vez".** Uma migração, um reinício numa
janela, um lembrete para um script. Qualquer coisa que se repete pertence a um
dos outros três.

E o `atd` tem que estar rodando, o que num servidor mínimo muitas vezes não está
— `systemctl status atd` antes de depender dele.
