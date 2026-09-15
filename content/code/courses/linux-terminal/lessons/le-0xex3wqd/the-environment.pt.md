---
title: O ambiente não é o seu, e é por isso que funcionou no seu shell
version: 1
---

**Esta é a seção.** Mais jobs agendados falham aqui do que em todo o resto desta
aula somado, e eles falham do jeito mais difícil de notar: nada acontece.

## O que o cron te dá de verdade

Um job foi agendado como `report.sh` — um script em `~/bin`, que está no `PATH`
desta conta. O cron mandou isto de volta:

```
Subject: Cron <ana@vm> report.sh (failed)
MIME-Version: 1.0
Content-Type: text/plain; charset=US-ASCII
Content-Transfer-Encoding: quoted-printable
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/home/ana>
X-Cron-Env: <PATH=/usr/bin:/bin>
X-Cron-Env: <LOGNAME=ana>
Message-Id: <20260915123115.CCA069827E@vm>
Date: Tue, 15 Sep 2026 12:31:01 +0000 (UTC)

/bin/sh: 1: report.sh: not found
```

**O cron põe o próprio ambiente nos cabeçalhos**, e lá está ele:

| | |
|---|---|
| `SHELL=/bin/sh` | não é o bash. É o `dash`, no Debian e no Ubuntu |
| `PATH=/usr/bin:/bin` | quatro diretórios a menos que o seu |
| `HOME=/home/ana` | esse está certo |
| `LOGNAME=ana` | e esse também |

**Sem `~/.bashrc`, sem `~/.profile`, sem `/etc/profile`.** Os arquivos de
inicialização da aula 9 são para shells interativos e de login, e um job do cron
não é nem um nem outro. Qualquer coisa que você tenha posto neles — uma linha de
`PATH`, um `source venv/bin/activate`, um alias, uma variável de proxy, um
`JAVA_HOME` — está ausente.

É por isso que o job funciona quando você o cola no seu terminal e falha às três
da manhã. **Você está testando num programa diferente.**

## Três correções, em ordem de quão bem funcionam

```sh
# 1. absolute paths, everywhere
* * * * * /home/ana/bin/report.sh

# 2. set PATH at the top of the crontab
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin
* * * * * report.sh

# 3. make the job a script that sets up its own world
* * * * * /home/ana/bin/report-wrapper.sh
```

**Caminhos absolutos são a que nunca surpreende ninguém.** A linha do `PATH`
funciona e é invisível para quem lê uma linha do seu crontab. O wrapper é o que
você quer quando o job precisa de mais que um caminho — um virtualenv, um `cd`,
credenciais vindas de um arquivo.

## Teste do jeito que o cron vai rodar

```
ana@vm:~/work/cron$ which report.sh
/home/ana/bin/report.sh
ana@vm:~/work/cron$ env -i SHELL=/bin/sh PATH=/usr/bin:/bin HOME=$HOME LOGNAME=$USER /bin/sh -c 'report.sh'; echo "exit $?"
/bin/sh: 1: report.sh: not found
exit 127
ana@vm:~/work/cron$ env -i SHELL=/bin/sh PATH=/usr/bin:/bin HOME=$HOME LOGNAME=$USER /bin/sh -c '/home/ana/bin/report.sh'; echo "exit $?"
report ran
exit 0
```

O `env -i` começa com um ambiente vazio e devolve exatamente as quatro variáveis
que os cabeçalhos do próprio cron listaram. **A primeira linha acha o script. A
segunda, rodada do jeito que o cron roda, não acha** — o mesmo
`/bin/sh: 1: report.sh: not found`, e `127`, que é o status de saída do shell
para *não encontrei isso*.

**Se funcionar sob o `env -i`, vai funcionar às três da manhã.** Dez segundos, em
vez de uma noite de espera para descobrir.

## O sinal de porcentagem, que não é um sinal de porcentagem

O segundo job quebrado era esta linha:

```sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

e isto é o que o cron mandou de volta:

```
Subject: Cron <ana@vm> echo "ran at $(date + (failed)
...
/bin/sh: 1: Syntax error: end of file unexpected (expecting ")")
```

**Leia a linha do assunto.** O comando que o cron rodou foi `echo "ran at $(date
+` e mais nada — porque **num crontab, um `%` sem escape termina o comando**.
Tudo depois do primeiro `%` vira a entrada padrão do job, e as quebras de linha
que você não digitou são os `%` restantes.

Então o shell recebeu um `$(` sem fechar, e disse isso.

```sh
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
```

**Uma contrabarra antes de cada `%`.** Isso morde o `date`, o `find -printf`, as
strings de formato do `awk`, e todo `printf` numa linha de crontab.

Ele tem um uso — o `%` é como se canaliza entrada para um job numa linha só — e o
uso é mais raro que o acidente por uma larga margem. **O hábito que evita isso
por completo é pôr qualquer coisa com um `%` num script** e agendar o script.

## O crontab corrigido, e o que ele produziu

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
ana@vm:~/work/cron$ cat pct.log
ran at 12:33
ran at 12:34
ana@vm:~/work/cron$ cat report.log
report ran
report ran
ana@vm:~/work/cron$ tail -3 beat.log
2026-09-15 12:32:01 heartbeat, pid 19067
2026-09-15 12:33:01 heartbeat, pid 19166
2026-09-15 12:34:01 heartbeat, pid 19232
```

Três jobs, três arquivos, um por minuto, no minuto. **E nenhum e-mail chegou** —
que é o assunto da próxima seção, e a razão de um cron silencioso não ser a mesma
coisa que um cron funcionando.
