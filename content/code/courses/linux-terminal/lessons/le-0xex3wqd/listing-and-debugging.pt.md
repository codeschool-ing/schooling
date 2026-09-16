---
title: O que está agendado nesta máquina, e se rodou
version: 1
---

Duas perguntas, e você vai fazer as duas numa máquina que não foi você que
configurou.

## Tudo que está agendado

```sh
crontab -l                                  # yours
sudo crontab -u www-data -l                 # somebody else's
sudo ls -la /var/spool/cron/crontabs/       # who has one at all
cat /etc/crontab                            # the system one
ls -la /etc/cron.d/ /etc/cron.*ly/          # packages, and the run-parts dirs
systemctl list-timers --all                 # every timer, enabled or not
sudo atq                                    # one-shot jobs waiting
```

**Sete lugares.** Nada imprime todos, e um job que você não acha normalmente está
naquele que você não conferiu — quase sempre o `/etc/cron.d`, porque ninguém o
pôs lá à mão.

Uma primeira passada que pega a maior parte:

```sh
sudo grep -rs --include='*' '' /etc/cron.d /etc/crontab /var/spool/cron
```

## O `systemctl list-timers`

Esta máquina não consegue rodar isso, e diz na cara:

```
ana@vm:~/work/cron/units$ systemctl list-timers --all
System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
```

O PID 1 neste contêiner não é o systemd — o mesmo limite que a aula 5 encontrou,
pela mesma razão, e a mesma honestidade se aplica aqui: **o que vem a seguir é um
desenho da saída daquele comando, não uma captura.**

```
NEXT                        LEFT     LAST                        PASSED  UNIT             ACTIVATES
Tue 2026-09-15 13:00:00 UTC 14min    Tue 2026-09-15 12:00:00 UTC 45min   sysstat-collect… sysstat-collect.service
Wed 2026-09-16 00:00:00 UTC 11h      Tue 2026-09-15 00:00:12 UTC 12h     logrotate.timer  logrotate.service
Wed 2026-09-16 03:00:00 UTC 14h      Tue 2026-09-15 03:00:19 UTC 9h      report.timer     report.service
Wed 2026-09-16 06:12:44 UTC 17h      Tue 2026-09-15 06:12:44 UTC 6h      apt-daily.timer  apt-daily.service
-                           -        -                           -       systemd-tmpfile… systemd-tmpfiles-clean.service

5 timers listed.
```

**`NEXT` e `LAST` são as duas colunas que valem o comando.** Um timer cujo `LAST`
é mais velho que o período dele não rodou, e isso é um fato sobre o qual você pode
agir. Os traços na última linha são um timer carregado que nunca disparou.

O `--all` inclui os que não estão ativos; sem ele você vê só os vivos, e um timer
desabilitado é exatamente o que você está procurando quando um job parou.

## Rodou?

| | |
|---|---|
| `grep CRON /var/log/syslog` | cron, no Debian e no Ubuntu |
| `journalctl -u cron` | cron, pelo journal |
| `journalctl -u report.service` | o job de um timer, saída incluída |
| `journalctl -u report.service --since yesterday` | desde quando |
| `systemctl status report.timer` | quando ele dispara em seguida |
| `systemctl status report.service` | como a última execução terminou |

**O journal é a vantagem do timer sobre o cron aqui.** A saída de um job do cron
vai para o e-mail — se houver um MTA, se alguém ler. O job de um timer roda sob o
systemd, então **a saída padrão e a de erro vão para o journal**, com o nome da
unidade, a hora e o status de saída, e elas estão lá daqui a uma semana quando
você quiser.

## Uma lista para "não rodou"

Nesta ordem, porque cada item é mais barato que o seguinte:

1. **Está no crontab que você acha?** `crontab -l`, na conta que você acha. O
   `sudo crontab -u deploy -l` é a resposta com mais frequência do que deveria.
2. **O daemon está rodando?** `systemctl status cron`, `systemctl status atd`. Um
   contêiner que nunca iniciou o cron é uma classe inteira disso.
3. **O cron tentou?** `grep CRON /var/log/syslog`. Uma linha `CMD` quer dizer que
   o job começou e o problema está dentro dele; nenhuma linha quer dizer que a
   agenda está errada ou que o cron nunca leu o arquivo.
4. **A agenda é o que você quis dizer?** A regra do OU da seção 04, o `*/15`
   contando a partir do zero, e para um timer, o `systemd-analyze calendar` na
   string exata.
5. **O arquivo tem o nome certo?** Um ponto num nome do `/etc/cron.d`, ou uma
   quebra de linha final faltando, e o arquivo é ignorado sem uma palavra.
6. **É o ambiente?** O `env -i` da seção 06, que reproduz a falha no seu terminal
   em dez segundos.
7. **Ele ainda está rodando da vez passada?** Seção 14. Dê um `ps -ef | grep` no
   comando, e olhe há quanto tempo ele está lá.

**Os passos 3 e 6 juntos cobrem a maior parte**, e os dois levam dez segundos. A
razão de a lista estar nesta ordem é que todo mundo começa pelo passo 6 e a
resposta normalmente é o passo 1.
