---
title: Nove coisas de que um job agendado precisa, seja quem for que o inicie
version: 2
---

Esta é a seção que sobrevive ao agendador. Cron, um timer do systemd, um
`CronJob` do Kubernetes, Airflow — todos eles iniciam um programa e vão embora, e
tudo abaixo é sobre o programa.

## As nove

| | |
|---|---|
| 1 | **caminhos absolutos**, para o programa e para todo arquivo que ele toca |
| 2 | **`set -euo pipefail`**, para que uma falha seja uma falha — aula 9 |
| 3 | **uma trava**, para que ele não rode duas vezes ao mesmo tempo — seção 14 |
| 4 | **um tempo limite**, para que um travamento não seja permanente |
| 5 | **saída que vai para onde você vai ler** — seção 07 |
| 6 | **saída diferente de zero quando falha**, que é do que todo o resto depende |
| 7 | **idempotência**: rodar duas vezes não causa dano |
| 8 | **um comentário dizendo por que ele existe** |
| 9 | **alguém avisado quando ele para** |

Oito dessas são uma linha cada. A nona é a que é de fato difícil.

## A forma

O script precisa de logs para arquivar. Três dias de logs de uma aplicação
pequena, com o nome pela data, do jeito que a maioria das aplicações nomeia:

```sh
mkdir -p ~/srv/app/logs ~/srv/archive && cd ~/srv/app/logs
for d in "$(date -d '2 days ago' +%F)" "$(date -d yesterday +%F)" "$(date +%F)"; do
  printf '%s 03:00:01 app started\n%s 03:00:02 app ready\n' "$d" "$d" > "app-$d.log"
done
```

E o script, no diretório da aula 9:

```sh
cd ~/work/scripts
cat > upload-logs.sh <<'END'
#!/bin/bash
# Archives yesterday's logs.
# Scheduled: 03:17 daily, ana's crontab. Safe to run by hand, safe to run twice.
set -euo pipefail

LOG=/home/ana/work/cron/upload-logs.log
exec >> "$LOG" 2>&1
echo "=== $(date '+%F %T') starting"

cd /home/ana/srv/app/logs

yesterday=$(date -d yesterday +%F)
archive="/home/ana/srv/archive/logs-$yesterday.tar.gz"

if [ -f "$archive" ]; then
    echo "already done for $yesterday"
    exit 0
fi

tar czf "$archive.tmp" "app-$yesterday".*
mv "$archive.tmp" "$archive"
echo "=== $(date '+%F %T') archived $(basename "$archive")"
END
chmod +x upload-logs.sh
```

E rodado duas vezes, uma atrás da outra:

```
ana@vm:~/work/scripts$ shellcheck upload-logs.sh && echo "shellcheck clean"
shellcheck clean
ana@vm:~/work/scripts$ ./upload-logs.sh; echo "exit $?"
exit 0
ana@vm:~/work/scripts$ ./upload-logs.sh; echo "exit $?"
exit 0
ana@vm:~/work/scripts$ cat /home/ana/work/cron/upload-logs.log
=== 2026-10-07 14:39:34 starting
=== 2026-10-07 14:39:35 archived logs-2026-10-06.tar.gz
=== 2026-10-07 14:39:35 starting
already done for 2026-10-06
ana@vm:~/work/scripts$ ls -l /home/ana/srv/archive/
total 4
-rw-rw-r-- 1 ana ana 159 Oct  7 14:39 logs-2026-10-06.tar.gz
```

**As duas execuções não imprimiram nada e saíram com 0**, que é o que o cron quer:
sem saída, sem e-mail. O log diz o que aconteceu, a segunda execução diz `already
done`, e há exatamente um arquivo — que é idempotência, demonstrada em vez de
afirmada.

Cinco coisas no script valem ser nomeadas:

**`exec >> "$LOG" 2>&1`** redireciona o resto do script uma vez, em vez de um `>>`
em cada linha — que é por que as duas execuções acima não imprimiram nada no
terminal. O cron não tem nada para mandar por e-mail quando funciona.

**O `cd` na própria linha, sob `set -e`.** O argumento da aula 9: se o diretório
sumiu, o script para ali em vez de fazer o trabalho em outro lugar.

**O `.tmp` e o `mv`.** Uma renomeação dentro de um sistema de arquivos é atômica,
então um leitor nunca vê um arquivo pela metade, e um job morto no meio deixa um
`.tmp` em vez de um arquivo corrompido que parece pronto.

**A guarda `if [ -f "$archive" ]`** é como a idempotência se parece na prática. São
quatro linhas e é o que torna seguras uma execução atrasada, uma retentativa e
alguém rodando à mão.

**O comentário nomeando a agenda.** O script é achado por quem está depurando às
três da manhã, e o crontab não está aberto na frente dessa pessoa.

## A linha de crontab que vai com ele

```sh
# 03:17 daily — archive yesterday's logs. Timeout 10m, skip if still running.
17 3 * * * /usr/bin/flock -E 0 -n /run/lock/upload-logs /usr/bin/timeout 600 /home/ana/bin/upload-logs.sh
```

Longa, e cada palavra dela é uma das nove.

Eis aquela linha, numa agenda de um minuto para poder ser observada. O arquivo
e o log das duas execuções acima são apagados antes, para a primeira execução
agendada ter trabalho a fazer, e o crontab é substituído:

```sh
cd ~/work/cron
rm -f ~/srv/archive/* upload-logs.log
cat > survive.cron <<'END'
MAILTO=ana
PATH=/usr/local/bin:/usr/bin:/bin

# every minute (for this demonstration) — archive yesterday's logs.
# skip if the last run is still going; give up after 60 seconds.
* * * * * /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh
END
crontab survive.cron
sleep 190
```

Três minutos depois:

```
ana@vm:~/work/cron$ crontab -l
MAILTO=ana
PATH=/usr/local/bin:/usr/bin:/bin

# every minute (for this demonstration) — archive yesterday's logs.
# skip if the last run is still going; give up after 60 seconds.
* * * * * /usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh
ana@vm:~/work/cron$ cat upload-logs.log
=== 2026-10-07 14:40:02 starting
=== 2026-10-07 14:40:03 archived logs-2026-10-06.tar.gz
=== 2026-10-07 14:41:01 starting
already done for 2026-10-06
=== 2026-10-07 14:42:02 starting
already done for 2026-10-06
ana@vm:~/work/cron$ ls -l /home/ana/srv/archive/
total 4
-rw-rw-r-- 1 ana ana 159 Oct  7 14:40 logs-2026-10-06.tar.gz
```

```
root@vm:~# grep upload-logs /var/log/syslog | tail -4
2026-10-07T14:40:01.902937+00:00 vm CRON[5076]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-10-07T14:41:01.343089+00:00 vm CRON[5093]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
2026-10-07T14:42:02.108397+00:00 vm CRON[5100]: (ana) CMD (/usr/bin/flock -E 0 -n /home/ana/work/cron/upload.lock /usr/bin/timeout 60 /home/ana/work/scripts/upload-logs.sh)
```

**Três execuções, um arquivo, e nenhum e-mail.** O log distingue a execução que
fez o trabalho das duas que corretamente não fizeram nada; o syslog diz que o cron
iniciou o job a cada minuto; e a caixa de correio não cresceu, porque
silêncio é o que um job funcionando parece.

Que é o problema inteiro com o nono item, abaixo.

Este crontab é uma demonstração e roda a cada minuto; depois de observá-lo, o
`crontab -r` o remove — a única vez em que aquela flag é exatamente o que você
quer.

## A nona: saber quando ele para

**Tudo acima te conta sobre um job que rodou e falhou. Nada te conta sobre um job
que nunca rodou** — o daemon que não foi iniciado, o crontab que foi apagado, o
contêiner reconstruído sem o arquivo.

Essa falha é invisível por construção: silêncio é o que o sucesso parece.

A correção é inverter. **O job informa que deu certo, e outra coisa reclama quando
o aviso não chega.** Um interruptor de homem morto:

```sh
# at the end of the script, after everything worked
curl -fsS --retry 3 https://monitor.example.com/ping/upload-logs > /dev/null
```

O monitor sabe que o job deve dar sinal diariamente; se não der, é o monitor que
levanta o alarme — e ele está em outro lugar, então sobrevive à máquina. Existem
serviços hospedados e um job de cron numa segunda máquina faz a mesma coisa.

**Um arquivo também funciona**, quando não há monitor:

```sh
date +%s > /var/lib/upload-logs/last-success
```

e alguma coisa que já roda — as verificações da frota, o próximo job da cadeia —
olha quão velho ele está.

## A regra por baixo das nove

**Teste o job do jeito que ele vai rodar**, não do jeito que você está rodando.

O `env -i` da seção 06 para o ambiente; `sudo -u ana` para a conta; `systemctl
start report.service` em vez do script à mão. Um job agendado é diferente do
mesmo comando no seu terminal de quatro jeitos — usuário, ambiente, diretório de
trabalho e terminal — e cada um deles tem o próprio jeito de falhar às três da
manhã.
