---
title: Os cinco campos, e a única regra que é um OU
version: 3
---

```localised
*  *  *  *  *  command
│  │  │  │  │
│  │  │  │  └── day of week   0-7   (0 and 7 are both Sunday)
│  │  │  └───── month         1-12
│  │  └──────── day of month  1-31
│  └─────────── hour          0-23
└────────────── minute        0-59
```

**A menor unidade é um minuto.** Nada no cron roda mais frequentemente que isso,
e um job que precisa disso é um job para um serviço que fica rodando — ou para o
timer do systemd da seção 12, que faz segundos.

| o que você escreve | o que quer dizer |
|---|---|
| `*` | todo valor |
| `5` | exatamente 5 |
| `1,15,30` | uma lista |
| `9-17` | um intervalo |
| `*/10` | a cada décimo valor — 0, 10, 20, 30, 40, 50 |
| `9-17/2` | um passo dentro de um intervalo — 9, 11, 13, 15, 17 |
| `mon`, `jan` | nomes, nos dois últimos campos, sem diferenciar maiúsculas |

## Leia estes até ficarem óbvios

| | |
|---|---|
| `0 3 * * *` | 03:00 todo dia |
| `*/15 * * * *` | a cada quinze minutos |
| `0 */4 * * *` | a cada quatro horas, na hora cheia |
| `30 2 * * 0` | 02:30 aos domingos |
| `0 9 1 * *` | 09:00 no primeiro do mês |
| `0 9 * * 1-5` | 09:00 nos dias úteis |
| `15 14 1 * *` | 14:15 no primeiro do mês |
| `0 0 1 1 *` | meia-noite no primeiro de janeiro |

**`*/15` no campo dos minutos quer dizer quatro vezes por hora, e não a cada
quinze minutos.** É `0,15,30,45` — então um job que começa às 12:50 não roda em
seguida às 13:05, ele roda às 13:00. O passo conta a partir do zero, não a partir
de agora.

## A regra que surpreende todo mundo

**Se tanto o campo do dia do mês quanto o do dia da semana estiverem restritos, o
cron roda o job quando *qualquer um dos dois* casar.** Em todo o resto da linha
os campos são combinados com E. Esses dois são combinados com OU.

Isso vale medir em vez de acreditar. Três jobs, somados ao crontab da seção 03
numa quarta-feira que não era dia treze. Eles nomeiam esse dia: no seu, ponha o
dia da semana de hoje onde está o `3` — o `date +%w` o imprime, e domingo é 0 —,
use outro dia que não hoje onde está o `1`, e se hoje for dia treze, use 14 para
o dia do mês.

```sh
cd ~/work/cron
cat > or.cron <<'END'
* * 13 * 3 echo "dom 13 OR dow Wed fired at $(date +\%T)" >> /home/ana/work/cron/or.log
* * 13 * 1 echo "dom 13 OR dow Mon fired at $(date +\%T)" >> /home/ana/work/cron/or2.log
* * * * 3 echo "dow Wed only fired at $(date +\%T)" >> /home/ana/work/cron/or3.log
END
(crontab -l; cat or.cron) | crontab -
sleep 150          # two runs, at least
```

O `crontab -l`, ligado por pipe ao `crontab -` com as linhas novas depois, é como
você soma linhas a um crontab a partir de um script: o traço é a entrada padrão,
e o resultado inteiro substitui o antigo.

```
ana@vm:~/work/cron$ date "+today is %A %F"
today is Wednesday 2026-10-07
ana@vm:~/work/cron$ crontab -l | tail -3
* * 13 * 3 echo "dom 13 OR dow Wed fired at $(date +\%T)" >> /home/ana/work/cron/or.log
* * 13 * 1 echo "dom 13 OR dow Mon fired at $(date +\%T)" >> /home/ana/work/cron/or2.log
* * * * 3 echo "dow Wed only fired at $(date +\%T)" >> /home/ana/work/cron/or3.log
ana@vm:~/work/cron$ cat or.log
dom 13 OR dow Wed fired at 14:28:02
dom 13 OR dow Wed fired at 14:29:02
dom 13 OR dow Wed fired at 14:30:02
ana@vm:~/work/cron$ cat or2.log
cat: or2.log: No such file or directory
ana@vm:~/work/cron$ cat or3.log
dow Wed only fired at 14:28:02
dow Wed only fired at 14:29:02
dow Wed only fired at 14:30:02
```

**O primeiro job rodou no dia sete**, porque é uma quarta — o dia do mês nunca
casou e não precisou. **O segundo não rodou nenhuma vez**, porque nem o dia treze
nem segunda-feira eram verdade. O terceiro é o controle: uma restrição simples de
dia da semana faz o que você espera.

Então `0 3 13 * 5` **não** é "3h da manhã na sexta-feira treze". É *o dia treze de
todo mês, e também toda sexta-feira* — cerca de 64 execuções por ano onde você
queria uma ou duas.

**Não há jeito de escrever "sexta-feira treze" em cinco campos.** O jeito como
isso é feito:

```sh
0 3 13 * *  [ "$(date +\%u)" = 5 ] && /home/ana/bin/job.sh
```

Restrinja um campo no cron, e teste o outro no comando.

## Os atalhos

| | |
|---|---|
| `@yearly`, `@annually` | `0 0 1 1 *` |
| `@monthly` | `0 0 1 * *` |
| `@weekly` | `0 0 * * 0` |
| `@daily`, `@midnight` | `0 0 * * *` |
| `@hourly` | `0 * * * *` |
| `@reboot` | uma vez, quando o cron inicia |

**O `@reboot` não é uma agenda e é o que merece um aviso.** Ele roda quando o
*cron* inicia, que normalmente mas nem sempre é perto do boot, ele não roda se o
cron for reiniciado sem a máquina reiniciar — e não é assim que um programa que
deveria estar sempre rodando é iniciado. Isso é um serviço do systemd (aula 5),
que o reinicia quando ele morre, o registra, e o ordena depois das coisas de que
ele precisa.

## Dois hábitos

**Escreva a agenda como um comentário acima da linha**, em palavras:

```sh
# 03:15 every day — rotate and upload yesterday's logs
15 3 * * * /home/ana/bin/upload-logs.sh
```

A sintaxe do cron é legível numa direção e não na outra; o comentário é o que
alguém lê às três da manhã quando o job é o suspeito.

**Não agende tudo na hora cheia.** Cada máquina sua rodando o backup às
`0 3 * * *` é uma manada avançando contra um servidor de arquivos. Escolha um
minuto sem significado — `17 3 * * *` — que é por que o `/etc/crontab` roda os
jobs de hora em hora aos 17 minutos.
