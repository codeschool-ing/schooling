---
title: O `OnCalendar`, e o comando que te diz quando ele vai disparar
version: 1
---

```
DiaDaSemana Ano-Mês-Dia Hora:Minuto:Segundo
```

Tudo é opcional, o `*` é qualquer um, e a coisa inteira tem um conferidor — que o
cron não tem, e que é o melhor argumento isolado a favor dos timers.

## O `systemd-analyze calendar`

```
ana@vm:~/work/cron$ systemd-analyze calendar "Mon *-*-* 03:00:00"
Normalized form: Mon *-*-* 03:00:00
    Next elapse: Mon 2026-09-21 03:00:00 UTC
       From now: 5 days left
```

**Três linhas, e a do meio é a resposta.** Não "isto analisa" — *esta é a data em
que vai rodar de verdade*. Rode antes de instalar o timer, toda vez.

O `--iterations` mostra mais de uma:

```
ana@vm:~/work/cron$ systemd-analyze calendar --iterations=5 "*-*-* *:00/15:00"
Normalized form: *-*-* *:00/15:00
    Next elapse: Tue 2026-09-15 12:45:00 UTC
       From now: 14min left
   Iteration #2: Tue 2026-09-15 13:00:00 UTC
       From now: 29min left
   Iteration #3: Tue 2026-09-15 13:15:00 UTC
       From now: 44min left
   Iteration #4: Tue 2026-09-15 13:30:00 UTC
       From now: 59min left
   Iteration #5: Tue 2026-09-15 13:45:00 UTC
       From now: 1h 14min left
```

O `*:00/15:00` é "minuto 0, e então a cada 15" — quatro vezes por hora, e as
cinco datas provam isso em vez de prometer.

## A sintaxe

| | |
|---|---|
| `*-*-* 03:00:00` | 03:00 todo dia |
| `03:00` | a mesma coisa — a parte da data assume todo dia |
| `Mon..Fri 09:00` | dias úteis às nove |
| `Sat,Sun 10:00` | uma lista de dias |
| `*-*-01 00:00:00` | meia-noite no primeiro |
| `*-01-01 00:00:00` | ano novo |
| `*:0/10` | a cada dez minutos |
| `*-*-* *:00:00` | toda hora, na hora cheia |
| `2026-12-25 08:00:00` | uma vez, numa data fixa |
| `Mon *-*-* 03:00:00` | segundas às três |

**Segundos existem.** O `*:*:0/30` é a cada trinta segundos, que o cron não sabe
expressar de jeito nenhum.

## Os atalhos, e no que eles se expandem

```
ana@vm:~/work/cron$ systemd-analyze calendar daily weekly monthly
  Original form: daily
Normalized form: *-*-* 00:00:00
    Next elapse: Wed 2026-09-16 00:00:00 UTC
       From now: 11h left

  Original form: weekly
Normalized form: Mon *-*-* 00:00:00
    Next elapse: Mon 2026-09-21 00:00:00 UTC
       From now: 5 days left

  Original form: monthly
Normalized form: *-*-01 00:00:00
    Next elapse: Thu 2026-10-01 00:00:00 UTC
       From now: 2 weeks 1 day left
```

**O `weekly` aqui é segunda-feira**, onde o `@weekly` do cron é domingo. Não são a
mesma agenda, e um job portado de um para o outro se move um dia.

`hourly`, `daily`, `weekly`, `monthly`, `quarterly`, `yearly` e `minutely` todos
existem, e todos são **meia-noite exata**, que é o minuto mais cheio de qualquer
máquina — a razão de o `RandomizedDelaySec=` estar no timer da seção anterior.

## Os dois campos de dia, que é onde ele difere do cron

```
ana@vm:~/work/cron$ systemd-analyze calendar "*-*-13 05:00:00" --iterations=3
Normalized form: *-*-13 05:00:00
    Next elapse: Tue 2026-10-13 05:00:00 UTC
       From now: 3 weeks 6 days left
   Iteration #2: Fri 2026-11-13 05:00:00 UTC
       From now: 1 month 28 days left
   Iteration #3: Sun 2026-12-13 05:00:00 UTC
       From now: 2 months 27 days left
```

O dia treze de todo mês. Agora acrescente um dia da semana:

```
ana@vm:~/work/cron$ systemd-analyze calendar "Fri *-*-13" --iterations=2
  Original form: Fri *-*-13
Normalized form: Fri *-*-13 00:00:00
    Next elapse: Fri 2026-11-13 00:00:00 UTC
       From now: 1 month 28 days left
   Iteration #2: Fri 2027-08-13 00:00:00 UTC
       From now: 10 months 27 days left
```

**O systemd combina os dois campos de dia com E onde o cron combina com OU**
(seção 213). `Fri *-*-13` é mesmo sexta-feira treze — e as duas datas que ele
imprime estão a nove meses de distância, que é a mesma agenda que o cron teria
rodado umas sessenta e quatro vezes por ano.

O `systemd-analyze calendar` é como você descobre qual dos dois você escreveu, em
um segundo, antes de ser uma agenda de que alguém depende.

## O que ele faz quando a resposta é nada

```
ana@vm:~/work/cron$ systemd-analyze calendar "*-02-30 03:00:00"; echo "exit $?"
Normalized form: *-02-30 03:00:00
    Next elapse: never
exit 0
ana@vm:~/work/cron$ systemd-analyze calendar "*-*-* 25:00:00"; echo "exit $?"
Failed to parse calendar specification '*-*-* 25:00:00': Invalid argument
exit 1
```

**O dia trinta de fevereiro analisa, sai com 0, e acontece `never`.** Uma hora 25
não analisa de jeito nenhum e sai com 1. Então um script que confere o status de
saída pega o segundo e perde o primeiro: **a palavra a procurar é `never`**, e não
o status.

Um timer que nunca dispara é o equivalente no systemd de uma linha de cron com um
ponto no nome do arquivo: correto, instalado e morto.
