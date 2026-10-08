---
title: O ambiente não é o seu, e é por isso que funcionou no seu shell
version: 2
---

**Esta é a seção.** Mais jobs agendados falham aqui do que em todo o resto desta
aula somado, e eles falham do jeito mais difícil de notar: nada acontece.

## O que o cron te dá de verdade

Pergunte a ele. Mais uma linha no crontab da seção 03: um job cujo trabalho
inteiro é anotar o ambiente que recebeu.

```sh
cd ~/work/cron
(crontab -l; echo '* * * * * env > /home/ana/work/cron/cronenv.txt') | crontab -
sleep 70
```

```
ana@vm:~/work/cron$ cat cronenv.txt
HOME=/home/ana
LOGNAME=ana
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
LANG=C.UTF-8
SHELL=/bin/sh
PWD=/home/ana
ana@vm:~/work/cron$ echo "$PATH"
/home/ana/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin
```

**Seis variáveis, e é com isso tudo que um job do cron começa.**

| | |
|---|---|
| `SHELL=/bin/sh` | não é o bash. É o `dash`, no Debian e no Ubuntu |
| `PATH=…` | o padrão do sistema, que o cron do Ubuntu tira do `/etc/environment` |
| `HOME=/home/ana` | esse está certo |
| `LOGNAME=ana` | e esse também |

Ponha as duas linhas de `PATH` lado a lado. A do cron tem os diretórios do
sistema e **não tem o `/home/ana/bin`**, que o seu login acrescentou, nem nada que
o seu `~/.bashrc` acrescente. O cron de outras distribuições começa de um ainda
mais curto — `/usr/bin:/bin` é comum —, então um job que depende do `PATH` está
dependendo da distribuição.

**Sem `~/.bashrc`, sem `~/.profile`, sem `/etc/profile`.** Os arquivos de
inicialização da aula 9 são para shells interativos e de login, e um job do cron
não é nem um nem outro. Qualquer coisa que você tenha posto neles — uma linha de
`PATH`, um `source venv/bin/activate`, um alias, uma variável de proxy, um
`JAVA_HOME` — está ausente.

Foi isso que aconteceu com a segunda linha do crontab da seção 03. O `report.sh`
mora em `~/bin`, e o cron mandou isto de volta:

```
ana@vm:~/work/cron$ sed -n '/^Subject: Cron <ana@vm> report.sh/,/not found/p' /var/mail/ana | head -11
Subject: Cron <ana@vm> report.sh
MIME-Version: 1.0
Content-Type: text/plain; charset=UTF-8
Content-Transfer-Encoding: quoted-printable
X-Cron-Env: <SHELL=/bin/sh>
X-Cron-Env: <HOME=/home/ana>
X-Cron-Env: <LOGNAME=ana>
Message-Id: <20261007142803.68121402CC@vm>
Date: Wed,  7 Oct 2026 14:28:02 +0000 (UTC)

/bin/sh: 1: report.sh: not found
```

**A linha do assunto é o comando, e o corpo é o que ele imprimiu** — o shell,
dizendo que procurou o `report.sh` no `PATH` do cron e não achou. Os cabeçalhos
`X-Cron-Env` listam parte do ambiente que o job teve; o arquivo acima é ele
inteiro.

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

O arquivo que o job escreveu é exatamente o ambiente que o cron dá, então use-o:

```
ana@vm:~/work/cron$ which report.sh
/home/ana/bin/report.sh
ana@vm:~/work/cron$ env -i $(cat cronenv.txt) /bin/sh -c 'report.sh'; echo "exit $?"
/bin/sh: 1: report.sh: not found
exit 127
ana@vm:~/work/cron$ env -i $(cat cronenv.txt) /bin/sh -c '/home/ana/bin/report.sh'; echo "exit $?"
report ran
exit 0
```

O `env -i` começa com um ambiente vazio e devolve as seis variáveis que o cron
anotou. **A primeira linha acha o script. A segunda, rodada do jeito que o cron
roda, não acha** — o mesmo `report.sh: not found` do e-mail, e `127`, que é o
status de saída do shell para *não encontrei isso*. A terceira dá o caminho
absoluto e funciona.

**Se funcionar sob o `env -i`, vai funcionar às três da manhã.** Dez segundos, em
vez de uma noite de espera para descobrir.

## O sinal de porcentagem, que não é um sinal de porcentagem

O segundo job quebrado era esta linha:

```sh
* * * * * echo "ran at $(date +%H:%M)" >> /home/ana/work/cron/pct.log
```

e isto é a linha do assunto e o corpo do que o cron mandou de volta:

```
ana@vm:~/work/cron$ grep -m1 '^Subject: Cron <ana@vm> echo' /var/mail/ana; grep -m1 'Syntax error' /var/mail/ana
Subject: Cron <ana@vm> echo "ran at $(date +
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

Os três jobs de novo, com as três correções feitas — uma linha de `PATH` para o
job que precisa dela, os sinais de porcentagem com escape, e a saída do
`report.sh` mandada para um arquivo. Instalá-lo substitui o crontab inteiro,
incluindo as linhas extras das seções 04 e 06:

```sh
cd ~/work/cron
cat > fixed.cron <<'END'
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
END
crontab fixed.cron
sleep 150
```

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/home/ana/bin:/usr/local/bin:/usr/bin:/bin

* * * * * /home/ana/work/cron/heartbeat.sh
* * * * * report.sh >> /home/ana/work/cron/report.log 2>&1
* * * * * echo "ran at $(date +\%H:\%M)" >> /home/ana/work/cron/pct.log
ana@vm:~/work/cron$ cat pct.log
ran at 14:34
ran at 14:35
ana@vm:~/work/cron$ cat report.log
report ran
report ran
ana@vm:~/work/cron$ tail -3 beat.log
2026-10-07 14:33:02 heartbeat, pid 4779
2026-10-07 14:34:01 heartbeat, pid 4803
2026-10-07 14:35:02 heartbeat, pid 4819
```

Três jobs, três arquivos, um por minuto, no minuto. **E nenhum e-mail novo** — que
é o assunto da próxima seção, e a razão de um cron silencioso não ser a mesma
coisa que um cron funcionando.
