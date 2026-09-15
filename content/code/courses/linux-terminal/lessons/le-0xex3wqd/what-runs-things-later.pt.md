---
title: Cinco coisas que rodam algo mais tarde, e a que você não deve escrever
version: 1
---

O trabalho tem sempre o mesmo formato. Alguma coisa tem que acontecer às três da
manhã, ou a cada dez minutos, ou uma vez na terça — e você não vai estar lá.

## A que você não deve escrever

```sh
while true; do
    backup.sh
    sleep 3600
done
```

**É a primeira coisa que todo mundo escreve e ela está errada de cinco jeitos**,
e o primeiro deles é mensurável em quinze segundos:

```sh
#!/bin/bash
# the "run it in a loop" pattern: work, then sleep
for i in 1 2 3; do
  date '+%T  cycle start'
  sleep 2                 # the work
  sleep 3                 # the interval
done
```

```
ana@vm:~/work/scripts$ ./drift.sh
12:33:41  cycle start
12:33:46  cycle start
12:33:51  cycle start
```

**O intervalo é de três segundos e os ciclos estão a cinco de distância.** O
trabalho está dentro do laço, então cada execução empurra a próxima para mais
tarde. Um backup de hora em hora que leva quatro minutos roda às 03:00, depois às
03:04, depois às 03:08, e no fim da semana está rodando à tarde.

Os outros quatro:

| | |
|---|---|
| ele morre com o seu terminal | o hangup da aula 6, a não ser que você tenha pensado no `nohup` |
| ele não sobrevive a um reinício | e nada o reinicia |
| ninguém sabe que ele existe | ele não está em nenhum arquivo em que um colega olharia |
| não há registro | nenhum log de quando rodou, ou se funcionou |

Cada um desses é resolvido, de uma vez, pelos agendadores abaixo.

## Os cinco

| | |
|---|---|
| **cron** | o clássico. Uma linha numa tabela, cinco campos de tempo, em todo Unix |
| **timers do systemd** | dois arquivos de unidade, um calendário mais rico, o journal e dependências |
| **anacron** | para máquinas que estão desligadas às três da manhã |
| **`at`** | uma vez, numa hora que você nomeia, e então ele some |
| o da própria aplicação | `CronJob` do Kubernetes, Airflow, Jenkins, o agendador do seu banco |

Esta aula é sobre os quatro primeiros. O quinto importa e é documentação de
outra pessoa, tirando uma coisa que ele compartilha com todos os outros, que é o
assunto da seção 225.

## Quais deles estão nesta máquina

```
ana@vm:~$ ls /etc/cron.d /etc/cron.daily
/etc/cron.d:
anacron  e2scrub_all  php  sysstat

/etc/cron.daily:
0anacron  apt-compat  dpkg  sysstat
```

**O cron já está rodando, e já está rodando coisas**, o que é verdade em quase
toda máquina Linux que você vai encontrar. O `sysstat` — a ferramenta que a aula
11 usou para o `iostat` e o `mpstat` — coleta as amostras dele a partir de um job
do cron, e o `apt-compat` é por que as suas listas de pacotes estão frescas de
manhã.

Você não está acrescentando um agendador a esta máquina. Você está acrescentando
uma linha a um que roda desde que ela foi instalada.

## O que cada seção te deve

O resto da aula é cron por oito seções, porque é o que está lá e porque tudo que
dá errado com ele dá errado em silêncio; timers do systemd por quatro, porque é
com o que um serviço novo é escrito; e três no fim sobre a parte que não é nem um
nem outro — travas, falha, e o job sobrevivendo ao próprio sucesso.
