---
title: O que está agendado nesta máquina, e se rodou
version: 2
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

```
ana@vm:~$ systemctl list-timers --all
NEXT                                 LEFT LAST                              PASSED UNIT                           ACTIVATES
Wed 2026-10-07 14:40:00 UTC           40s Wed 2026-10-07 14:30:01 UTC     9min ago sysstat-collect.timer          sysstat-collect.service
Wed 2026-10-07 15:31:43 UTC         52min Wed 2026-10-07 14:34:48 UTC 4min 31s ago anacron.timer                  anacron.service
Wed 2026-10-07 15:32:38 UTC         53min Wed 2026-10-07 14:11:30 UTC    27min ago fwupd-refresh.timer            fwupd-refresh.service
Thu 2026-10-08 00:00:00 UTC            9h Wed 2026-10-07 13:18:17 UTC            - dpkg-db-backup.timer           dpkg-db-backup.service
Thu 2026-10-08 00:00:00 UTC            9h Wed 2026-10-07 13:18:17 UTC            - logrotate.timer                logrotate.service
Thu 2026-10-08 00:07:00 UTC            9h -                                      - sysstat-summary.timer          sysstat-summary.service
Thu 2026-10-08 03:01:02 UTC           12h -                                      - report.timer                   report.service
Thu 2026-10-08 04:17:01 UTC           13h Wed 2026-10-07 13:18:17 UTC            - apt-daily.timer                apt-daily.service
Thu 2026-10-08 06:11:38 UTC           15h Wed 2026-10-07 13:18:17 UTC            - motd-news.timer                motd-news.service
Thu 2026-10-08 06:18:06 UTC           15h Wed 2026-10-07 13:18:17 UTC            - apt-daily-upgrade.timer        apt-daily-upgrade.service
Thu 2026-10-08 10:23:07 UTC           19h Wed 2026-10-07 13:18:17 UTC            - man-db.timer                   man-db.service
Thu 2026-10-08 13:58:57 UTC           23h Wed 2026-10-07 13:58:57 UTC    40min ago update-notifier-download.timer update-notifier-download.service
Thu 2026-10-08 14:08:38 UTC           23h Wed 2026-10-07 14:08:38 UTC    30min ago systemd-tmpfiles-clean.timer   systemd-tmpfiles-clean.service
Sun 2026-10-11 03:10:52 UTC        3 days Wed 2026-10-07 13:18:17 UTC            - e2scrub_all.timer              e2scrub_all.service
Mon 2026-10-12 01:21:44 UTC        4 days Wed 2026-10-07 13:18:17 UTC            - fstrim.timer                   fstrim.service
Sat 2026-10-17 13:44:00 UTC 1 week 2 days Wed 2026-10-07 13:18:17 UTC            - update-notifier-motd.timer     update-notifier-motd.service
-                                       - -                                      - apport-autoreport.timer        apport-autoreport.service
-                                       - -                                      - snapd.snap-repair.timer        snapd.snap-repair.service
-                                       - -                                      - ua-timer.timer                 ua-timer.service

19 timers listed.
```

**`NEXT` e `LAST` são as duas colunas que valem o comando.** Um timer cujo `LAST`
é mais velho que o período dele não rodou, e isso é um fato sobre o qual você pode
agir. O `report.timer` da seção 12 está lá, esperando 03:01:02 com um traço no
`LAST`, porque nunca disparou; o `anacron.timer` é o anacron da seção 09, iniciado
pelo systemd. As três linhas de traços lá embaixo são timers carregados e não
ativos.

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

O `report.timer` da seção 12 só vai disparar às três da manhã, mas o serviço
dele pode ser iniciado à mão, que é o teste que a seção 12 recomendou — e aí tudo
naquela tabela tem algo a dizer:

```
ana@vm:~$ sudo systemctl start report.service
ana@vm:~$ journalctl -u report.service --no-pager | tail -4
Oct 07 14:39:21 vm systemd[1]: Starting report.service - Nightly report...
Oct 07 14:39:21 vm report.sh[5031]: report ran
Oct 07 14:39:21 vm systemd[1]: report.service: Deactivated successfully.
Oct 07 14:39:21 vm systemd[1]: Finished report.service - Nightly report.
ana@vm:~$ systemctl status report.service --no-pager | head -6
○ report.service - Nightly report
     Loaded: loaded (/etc/systemd/system/report.service; static)
     Active: inactive (dead) since Wed 2026-10-07 14:39:21 UTC; 849ms ago
TriggeredBy: ● report.timer
    Process: 5031 ExecStart=/home/ana/bin/report.sh (code=exited, status=0/SUCCESS)
   Main PID: 5031 (code=exited, status=0/SUCCESS)
```

**O journal tem a execução**: o systemd iniciando o serviço, a saída do próprio
script com o nome e o id de processo dele — `report.sh[5031]: report ran` — e o
serviço terminando. O `status` diz como a última execução terminou,
`status=0/SUCCESS`, e qual timer o inicia. É tudo o que o e-mail de um job do cron
teria dito, e mais, sem nenhum sistema de e-mail envolvido.

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
