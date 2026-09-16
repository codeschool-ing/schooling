---
title: Três da manhã de quem, e as duas noites do ano em que dá errado
version: 1
---

"Rode às três" tem uma pergunta escondida dentro, e a resposta não é a que você
imaginaria.

## O cron usa o fuso da máquina

Não o seu, nem o do cliente, nem o do convite na sua agenda. O da máquina —
`/etc/localtime`, que o `timedatectl` define.

```sh
timedatectl                     # what this machine thinks the time is
cat /etc/timezone               # Debian and Ubuntu keep the name here
date                            # and the zone is in the output
```

**A maioria dos servidores está em UTC e esse é o padrão certo**, precisamente
porque remove esta pergunta. Uma frota em UTC tem uma três da manhã só.

## O `CRON_TZ` não é portável, e o jeito como ele falha é silencioso

O conselho que você vai achar é pôr `CRON_TZ` no topo do crontab. No cron do Red
Hat — o `cronie` — isso funciona e reagenda as linhas abaixo dele. No cron vixie
do Debian e do Ubuntu, **não é uma diretiva de jeito nenhum**:

```
ana@vm:~/work/cron$ crontab -l
MAILTO=""
CRON_TZ=America/New_York
* * * * * echo "CRON_TZ=[$CRON_TZ]  ran at $(date -u +\%H:\%M) UTC" >> /home/ana/work/cron/tzenv2.log
30 8 * * * echo "08:30 New York?" >> /home/ana/work/cron/tz830.log
ana@vm:~/work/cron$ date -u "+%H:%M UTC"; TZ=America/New_York date "+%H:%M %Z"
12:45 UTC
08:45 EDT
ana@vm:~/work/cron$ cat tzenv2.log
CRON_TZ=[America/New_York]  ran at 12:45 UTC
```

**Leia a última linha duas vezes.** A variável chegou ao job — ela está ali na
saída, `CRON_TZ=[America/New_York]`. E o job rodou às **12:45 UTC**, no minuto
UTC, numa máquina onde Nova York estava quatro horas atrás.

Então neste cron o `CRON_TZ` é uma variável de ambiente comum: exportada para o
job, ignorada pelo agendador. Uma linha escrita para `08:30 de Nova York` roda às
08:30 UTC — três horas e meia adiantada no verão, e nada avisa.

**O jeito portável é fazer a conversão você mesmo**, uma vez, no crontab, com um
comentário:

```sh
# 03:00 America/New_York = 07:00 UTC in summer, 08:00 in winter.
# This runs at 07:00 UTC year round, so it is 02:00 local for half the year.
0 7 * * * /home/ana/bin/nightly.sh
```

Feio, honesto, e é um registro escrito de uma decisão em vez de uma suposição.

Ou use um timer do systemd, que aceita o fuso na própria expressão:

```
ana@vm:~$ systemd-analyze calendar "*-*-* 03:00:00 America/New_York"
Normalized form: *-*-* 03:00:00 America/New_York
    Next elapse: Wed 2026-09-16 07:00:00 UTC
       From now: 18h left
```

**Três da manhã em Nova York, devolvido como 07:00 UTC** — e vai imprimir 08:00
no inverno, porque ele segue o fuso em vez de um deslocamento. Aquela linha faz o
que o comentário do crontab acima só documenta.

## As duas noites do ano

Uma máquina num fuso com horário de verão tem uma noite em que uma hora não
acontece e uma em que uma hora acontece duas vezes. Eis o que isso faz com um job
agendado para 02:30, passado pelo `systemd-analyze calendar` em Nova York, a
partir da sexta anterior à mudança da primavera:

```
ana@vm:~/work/cron$ TZ=America/New_York systemd-analyze calendar --iterations=4 --base-time=2026-03-06 "*-*-* 02:30:00"
Normalized form: *-*-* 02:30:00
    Next elapse: Fri 2026-03-06 02:30:00 EST
       (in UTC): Fri 2026-03-06 07:30:00 UTC
       From now: 6 months 10 days ago
   Iteration #2: Sat 2026-03-07 02:30:00 EST
       (in UTC): Sat 2026-03-07 07:30:00 UTC
       From now: 6 months 9 days ago
   Iteration #3: Mon 2026-03-09 02:30:00 EDT
       (in UTC): Mon 2026-03-09 06:30:00 UTC
       From now: 6 months 7 days ago
   Iteration #4: Tue 2026-03-10 02:30:00 EDT
       (in UTC): Tue 2026-03-10 06:30:00 UTC
       From now: 6 months 6 days ago
```

**Conte as datas: o dia 6, o 7, o 9.** O domingo dia 8 sumiu inteiro, porque às
02:00 daquela noite os relógios foram para 03:00 e 02:30 nunca existiu. O job não
roda atrasado. Ele não roda.

E no outono:

```
ana@vm:~/work/cron$ TZ=America/New_York systemd-analyze calendar --iterations=4 --base-time=2026-10-31 "*-*-* 01:30:00"
Normalized form: *-*-* 01:30:00
    Next elapse: Sat 2026-10-31 01:30:00 EDT
       (in UTC): Sat 2026-10-31 05:30:00 UTC
       From now: 1 month 15 days left
   Iteration #2: Sun 2026-11-01 01:30:00 EDT
       (in UTC): Sun 2026-11-01 05:30:00 UTC
       From now: 1 month 16 days left
   Iteration #3: Mon 2026-11-02 01:30:00 EST
       (in UTC): Mon 2026-11-02 06:30:00 UTC
       From now: 1 month 17 days left
```

01:30 acontece duas vezes em 1º de novembro, uma no EDT e uma no EST. **O systemd
roda uma vez** — a do EDT — e a linha `(in UTC)` é como você sabe qual. O
comportamento do cron naquela hora depende da implementação, e em algumas delas o
job roda duas vezes.

## O que fazer de verdade

| | |
|---|---|
| ponha os servidores em UTC | e pare de ter este problema |
| agende fora das 01:00–03:00 | em qualquer fuso que muda, essa janela é a que quebra |
| escreva o fuso num comentário | em toda linha em que o horário local era o ponto |
| deixe o job idempotente | seção 16, e a razão de uma execução dupla ser sobrevivível |

**"Fora das 01:00–03:00" é a correção barata que ninguém aplica.** Um relatório às
04:15 locais roda 365 vezes por ano em todo fuso da Terra; o mesmo relatório às
02:15 roda 364 vezes em Nova York e 366 no ano em que a regra muda.
