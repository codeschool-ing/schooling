---
title: Qual deles, na máquina em que você está de verdade
version: 1
---

## Lado a lado

| | cron | timer do systemd |
|---|---|---|
| **o que é** | uma linha | dois arquivos |
| **onde** | todo Unix, desde 1975 | toda máquina com systemd |
| **menor intervalo** | um minuto | um segundo |
| **sintaxe de calendário** | cinco campos | mais rica, e **conferível** |
| **os dois campos de dia** | OU — seção 04 | E |
| **execuções perdidas** | perdidas | `Persistent=true` |
| **execuções sobrepostas** | por sua conta | impedidas |
| **saída** | por e-mail, se houver MTA | o journal |
| **ambiente** | quatro variáveis, sem profile | o que a unidade disser |
| **dependências** | nenhuma | `After=`, `Requires=`, o grafo inteiro |
| **dispersão** | escreva você mesmo | `RandomizedDelaySec=` |
| **conferir** | a checagem de sintaxe do `crontab -e` | `systemd-analyze verify`, `calendar`, `list-timers` |
| **aprender** | dez minutos | uma tarde |

## A resposta

**Use o que a máquina já usa.**

Um servidor com quinze jobs no `/etc/cron.d` não quer um décimo sexto job que é um
timer, porque a próxima pessoa a olhar vai achar quinze e não dezesseis. Uma
máquina em que todo serviço é uma unidade não quer uma linha de crontab que
ninguém vai pensar em conferir.

Consistência vence a lista de recursos, e vence com folga.

## Quando quebrar essa regra

**Vá de timer** quando qualquer uma destas for verdade, porque cada uma é uma
coisa que você senão escreveria à mão e erraria:

| | |
|---|---|
| o job não pode se sobrepor | seção 14 |
| a máquina fica desligada parte do tempo | `Persistent=true` |
| o job precisa da rede, ou de uma montagem | `After=network-online.target` |
| a saída importa e não há MTA | o journal |
| ele roda em cem máquinas ao mesmo tempo | `RandomizedDelaySec=` |
| ele precisa rodar mais que uma vez por minuto | segundos existem |

**Fique com o cron** quando:

| | |
|---|---|
| a máquina não tem systemd | Alpine, busybox, alguns contêineres, Unix mais velhos |
| o job é uma linha e é seu | `crontab -e`, trinta segundos |
| todo o resto aqui já é cron | consistência |
| uma pessoa que não é você tem que ler | cinco campos vencem quarenta configurações |

## E a terceira resposta

**Se a máquina é descartável, nenhum dos dois.**

Um contêiner que é reagendado por um orquestrador não deveria ter um daemon de
cron dentro — o job pertence a um `CronJob` do Kubernetes, uma tarefa agendada do
ECS, um agendador de nuvem, ou o pipeline de que o contêiner faz parte. Esses te
dão o que esta aula passou oito seções acrescentando ao cron à mão: um registro de
cada execução, uma política de retentativa, um tempo limite, um alerta, e uma
definição que mora num repositório em vez de numa máquina.

A troca é que o agendador agora é o sistema de outra pessoa, com os modos de falha
dele e o lugar dele para olhar.

**O que não muda é a seção 16.** Seja o que for que inicie o job, o job ainda tem
que ser seguro para rodar duas vezes, dizer alguma coisa quando falha, e parar
quando demora demais. Essa é a metade desta aula que sobrevive a qualquer
agendador que você esteja usando neste ano.
