---
title: `journalctl`, e um log que sobrevive ao reboot
version: 2
---

**Vale aqui o mesmo aviso da seção 10.** Esta máquina roda um supervisor de contêiner como processo
um, então não existe journal para ler nem transcrição para tirar. Os comandos abaixo são os que
valem conhecer, as formas de saída são descritas em vez de coladas, e a seção 08 explica por quê.

## Para onde vai a saída de um serviço

A seção 07 disse que um daemon não tem terminal, então cada linha que ele escreve precisa ser
recolhida por alguma coisa. Numa máquina com systemd essa coisa é **o journal**: o systemd captura a
saída padrão e a saída de erro de tudo que ele inicia, e guarda.

É essa a decisão de projeto que vale nomear, porque ela muda como você escreve um serviço:
**o `ExecStart=` deve imprimir na tela, e não num arquivo.** Sem caminho de log, sem rotação, sem
permissões num diretório de log. A unit imprime; o journal recolhe.

O `/var/log/` continua existindo e muito software ainda escreve lá direto. Numa máquina moderna você
olha nos dois, e no `journalctl` primeiro.

## O log binário, e a discussão sobre ele

O journal **não é um arquivo de texto.** É um formato estruturado, indexado e binário, e essa é a
parte do systemd a que a tradição Unix mais se opõe — a seção 08 nomeou isso.

O que ele compra é real: cada linha carrega campos como dados, e não como texto que alguém precisa
desmontar de volta. O serviço, o PID, o usuário, a prioridade, o boot a que pertence. É por isso que
`journalctl -u nginx --since '1 hour ago' -p err` é um comando em vez de um `grep` mais um `awk`
mais um problema de manipulação de datas.

O que ele custa é que `cat` e `grep` deixam de funcionar nos seus logs. Você passa por uma
ferramenta, e se a ferramenta ou o arquivo estiver quebrado você tem uma tarde mais difícil do que
um arquivo de texto te daria.

As duas metades são verdade. Ele está na sua máquina de qualquer jeito.

## As seis flags que fazem o trabalho

```
journalctl -u nginx                     # one service
journalctl -u nginx -f                  # and follow it, like tail -f
journalctl -u nginx -n 50               # the last 50 lines
journalctl -u nginx --since '1 hour ago'
journalctl -u nginx -p err              # this priority and worse
journalctl -b                           # this boot, everything, in order
```

**`-u` e `-f` juntos são o par que você mais vai digitar.** Um terminal acompanhando o serviço,
outro provocando — a mesma forma do `tail -f` da seção 08 da aula 3, o que é de propósito.

`--since` e `--until` aceitam inglês corrente além de horários: `'10 min ago'`, `'yesterday'`,
`'2026-09-14 09:00'`. Isso vale mais do que parece quando alguém diz *quebrou lá pelas nove*.

`-p` recebe as prioridades do syslog, e pedir uma te dá ela **e tudo que for mais grave**:

| | |
|---|---|
| `0` emerg, `1` alert, `2` crit | raras, e ruins |
| `3` err | a que você pede |
| `4` warning | |
| `5` notice, `6` info | a conversa normal |
| `7` debug | desligado, a menos que alguém tenha ligado |

## O `-b` é o que as pessoas não conhecem

```
journalctl -b        # this boot
journalctl -b -1     # the previous boot
journalctl --list-boots
```

**É assim que se descobre por que uma máquina reiniciou**, e como se lê uma falha que aconteceu
durante o boot, antes de você conseguir entrar.

É também a resposta para a cascata com que a seção 10 terminou: um serviço que falhou porque outra
coisa falhou te mostra a confusão dele, e o `journalctl -b` mostra o boot em ordem, então a primeira
falha está acima da segunda.

## De quem é o journal, e por que você pode não ver nada

Por padrão um usuário comum vê **as mensagens dele** e não as do sistema. Dois grupos mudam isso, e
estar em qualquer um deles basta:

| | |
|---|---|
| `systemd-journal` | leitura completa do journal |
| `adm` | o mesmo, no Debian e no Ubuntu |

**Um `journalctl -u nginx` vazio como usuário comum normalmente quer dizer permissão, e não
ausência.** Tente com `sudo` antes de concluir que o serviço não disse nada.

## Ele pode não sobreviver a um reboot, e isso é um ajuste

```
journalctl --disk-usage
```

Se o `/var/log/journal/` existe, o journal é **persistente** e sobrevive a reboots. Se não existe, o
journal mora em `/run/log/journal/` — num tmpfs, em memória — e **some no próximo boot.**

Debian e Ubuntu vêm com persistente por padrão há anos; algumas imagens mínimas e a maioria dos
contêineres não. O conserto é um diretório:

```
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```

`journalctl --vacuum-time=30d` e `--vacuum-size=500M` podam, e o `SystemMaxUse=` no
`/etc/systemd/journald.conf` define o teto para ele nunca virar o disco cheio da seção 13 da aula 3.

## Mais dois que vale ter

```
journalctl -k                          # kernel messages only — dmesg, with timestamps you can read
journalctl -u nginx -o json-pretty     # every field of every entry
```

O `-o json-pretty` é o que prova o argumento do formato binário. Você recebe `_PID`, `_UID`,
`_SYSTEMD_UNIT`, `_HOSTNAME`, `_TRANSPORT` e mais uma dúzia como valores nomeados — coisas que num
log de texto teriam de ser extraídas de volta de uma linha que alguém formatou na mão.

## O que rodar quando algo quebra

Quatro comandos, nesta ordem, e eles são o diagnóstico comum inteiro:

```
systemctl --failed
systemctl status thatservice
journalctl -u thatservice -n 50
journalctl -b -p err
```

**Os dois primeiros normalmente bastam.** O terceiro é para quando as dez linhas do bloco de status
não bastaram, e o quarto é para quando a causa está em outro canto da máquina.
