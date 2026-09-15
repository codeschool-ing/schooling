---
title: Timers que contam a partir de um evento, e o que põe o atraso em dia
version: 1
---

O `OnCalendar=` é um relógio. A outra metade da seção `[Timer]` não é: ela conta
**a partir de alguma coisa que aconteceu**, e é para o que o cron não tem
equivalente nenhum.

| | conta a partir de |
|---|---|
| `OnBootSec=` | a máquina terminar de dar boot |
| `OnStartupSec=` | o próprio systemd iniciar |
| `OnActiveSec=` | este timer ser ativado |
| `OnUnitActiveSec=` | a última vez que **o serviço dele** foi iniciado |
| `OnUnitInactiveSec=` | a última vez que o serviço dele **terminou** |

## O padrão que você vai escrever mais

```ini
[Timer]
OnBootSec=15min
OnUnitActiveSec=1h
```

**Quinze minutos depois do boot, e a cada hora depois de cada execução.** Duas
linhas, e elas resolvem duas coisas de uma vez:

O `OnBootSec=15min` mantém o job longe da tempestade do boot. Uma máquina subindo
tem muito o que fazer, e um gerador de relatórios competindo com isso é um uso
ruim do primeiro minuto.

O `OnUnitActiveSec=1h` é **uma hora depois de a última execução começar, não na
hora cheia** — então um job que leva vinte minutos roda às 03:00, 04:00, 05:00, e
um job que leva noventa minutos roda às 03:00, 04:30, 06:00. Ele não consegue se
empilhar do jeito que o job do cron da seção 223 consegue.

E o `OnUnitInactiveSec=1h` é a versão mais estrita: uma hora depois de ele
**terminar**, o que garante uma hora cheia de silêncio entre execuções.

## O `Persistent=true`

```ini
[Timer]
OnCalendar=daily
Persistent=true
```

**A resposta para "a máquina estava desligada às três da manhã".** O systemd
anota quando o timer disparou pela última vez; com `Persistent=true` ele compara
isso com o relógio no boot, e se uma execução foi perdida ele roda o job na hora.

É o anacron, embutido, com um relógio — que é por que uma máquina com systemd
precisa muito menos do anacron do que precisava.

Duas coisas sobre isso que vale saber antes de ligar:

**Ele roda uma vez, não uma vez por perda.** Um laptop fechado por uma semana
volta e roda o job diário uma vez, não sete. Isso é o que você quer para um
relatório e não é o que você quer para qualquer coisa que processa uma fila por
data.

**"Na hora" quer dizer no boot**, junto com tudo mais que estava esperando — que é
a razão para combinar com `RandomizedDelaySec=` numa frota.

## O `RandomizedDelaySec=` e o `AccuracySec=`

```ini
[Timer]
OnCalendar=*-*-* 03:00:00
RandomizedDelaySec=30m
AccuracySec=1s
```

**O `RandomizedDelaySec=30m`** acrescenta um atraso aleatório entre zero e trinta
minutos, fixo por máquina e por timer. Duzentas máquinas com o mesmo arquivo de
unidade deixam de ser duzentas requisições simultâneas às 03:00.

**O `AccuracySec=`** é o botão oposto e surpreende as pessoas: o padrão dele é
**um minuto**, o que quer dizer que um timer marcado para 03:00:00 pode disparar
às 03:00:43. O systemd está deliberadamente agrupando timers para o processador
poder continuar dormindo. Se você realmente precisa do segundo, `AccuracySec=1s`
diz isso — e num laptop isso custa bateria, que é a razão inteira do padrão.

**Entre os dois, essas configurações são por que um timer não é só cron com mais
arquivos.** Uma espalha o trabalho de propósito; a outra o agrupa de propósito; e
o cron não sabe expressar nenhuma das duas.

## Um timer que é só um timer

```ini
[Timer]
OnCalendar=*-*-* 04:00:00
Unit=cleanup.service
```

O `Unit=` quebra a convenção de nomes, que é como um serviço ganha duas agendas —
um `cleanup-nightly.timer` e um `cleanup-weekly.timer`, os dois iniciando o
`cleanup.service`. **Não há jeito de fazer isso no cron a não ser escrevendo o
comando duas vezes.**

## Onde eles são escritos

```sh
/etc/systemd/system/          # yours, and it wins
/run/systemd/system/          # runtime, gone at reboot
/usr/lib/systemd/system/      # the package's
~/.config/systemd/user/       # yours, for --user timers
```

Mesma ordem dos serviços da aula 5, pela mesma razão: um arquivo em
`/etc/systemd/system` sombreia o do pacote, então uma atualização não desfaz a sua
mudança e a sua mudança não some com o pacote.

Para uma configuração só em vez de um arquivo inteiro, o `systemctl edit
report.timer` escreve um drop-in em `/etc/systemd/system/report.timer.d/` — e ele
abre o editor da seção 205 da aula 12 para fazer isso.
