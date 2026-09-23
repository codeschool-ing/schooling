---
title: Targets, e a máquina que não sobe
version: 2
---

Um **target** é um grupo nomeado de units. Nada mais: ele não roda programa nenhum e não tem
`ExecStart=`. Ele existe para que "leve a máquina a este estado" seja um nome só.

Você encontrou um na seção 09 sem que te dissessem o que era:

```
Created symlink …/etc/systemd/system/multi-user.target.wants/hello.service → /etc/systemd/system/hello.service.
```

O `multi-user.target` é o estado *a máquina está de pé, a rede funciona, os serviços estão rodando,
e ninguém é esperado numa tela gráfica*. Habilitar um serviço o colocou no diretório `wants` daquele
target — então chegar ao target o inicia.

## Targets substituíram os runlevels

O SysV tinha **runlevels**, numerados de 0 a 6, e você ainda vai encontrar os números em
documentação antiga e na memória muscular dos outros:

| runlevel | target | é |
|---|---|---|
| 0 | `poweroff.target` | desligado |
| 1 | `rescue.target` | usuário único, só root, serviços mínimos |
| 3 | `multi-user.target` | **o estado normal de um servidor** |
| 5 | `graphical.target` | o mesmo mais uma área de trabalho |
| 6 | `reboot.target` | reiniciando |

Os números eram uma ordem total — o nível 5 implicava tudo do nível 3 — o que era arrumado e não
conseguia expressar *este conjunto específico*. Targets são units com dependências, então eles se
compõem, e uma máquina pode ter quantos alguém definir.

```
systemctl get-default                       # what it boots into
sudo systemctl set-default multi-user       # boot without a desktop from now on
systemctl isolate rescue.target             # go there now
systemctl list-units --type=target          # what is active
```

**O `set-default` é um link simbólico**, exatamente como na seção 09: o
`/etc/systemd/system/default.target` apontando para o que você escolheu. Tudo no systemd é um link
simbólico em algum lugar, e quando você vê isso o projeto deixa de ser misterioso.

**O `isolate` não é o `start`.** Ele inicia aquele target e **para tudo que não está nele**, o que
num servidor em produção significa arrancar serviços de baixo de quem estava usando. Útil num
console de resgate; alarmante por ssh.

## Os que vale reconhecer

Além dos equivalentes de runlevel, quatro targets aparecem o tempo todo em arquivos de unit:

| | alcançado quando |
|---|---|
| `network.target` | a pilha de rede está **configurada**, que não é o mesmo que alcançável |
| `network-online.target` | algo de fato subiu — e só se um serviço `wait-online` estiver habilitado |
| `local-fs.target` | tudo do `/etc/fstab` está montado — seção 12 da aula 3 |
| `sysinit.target` | a preparação inicial de baixo nível terminou |

**`After=network.target` não quer dizer que a rede funciona.** Essa é de longe a suposição errada
mais comum numa unit escrita à mão: o serviço inicia, tenta abrir um endereço ou resolver um nome, e
falha uma vez no boot e funciona todas as vezes em que você inicia na mão.
`After=network-online.target` mais `Wants=network-online.target` é a versão honesta, e ela exige o
serviço `wait-online` habilitado, ou em silêncio não quer dizer nada de novo.

## Por que o boot é mais rápido, e como ver onde ele foi

A seção 08 disse que o systemd inicia coisas em paralelo resolvendo dependências em vez de rodar uma
lista numerada. Dá para observar o resultado:

```
systemd-analyze                     # how long the boot took, split into kernel and userspace
systemd-analyze blame               # every unit, slowest first
systemd-analyze critical-chain      # the chain that actually determined the total
```

**`blame` e `critical-chain` respondem perguntas diferentes, e as pessoas pegam a errada.** O
`blame` lista o que demorou mais; o `critical-chain` lista o que o total estava *esperando*. Uma
unit pode levar trinta segundos e não custar nada, porque ninguém estava esperando por ela. Conserte
a cadeia.

## A máquina que não sobe

Este é o assunto real da seção, e vale ter a sequência antes de precisar dela.

**Um boot para em algum lugar.** Ou ele trava, ou ele te joga num shell de emergência, e nos dois
casos a informação útil já está na tela ou no journal.

| sintoma | o que costuma ser |
|---|---|
| trava numa tarefa, com uma contagem regressiva | uma unit esperando algo que não vai chegar — a contagem é o timeout dela |
| `Give root password for maintenance` | um sistema de arquivos do `/etc/fstab` não pôde ser montado |
| shell de emergência, nada montado | o próprio sistema de arquivos raiz, ou um `fstab` bem errado |
| dá boot, e falta um serviço | seção 09: iniciado uma vez na mão, nunca habilitado |

**O do `fstab` é de longe o mais comum**, e a seção 12 da aula 3 te contou a defesa: `sudo mount -a`
depois de editar, e confirmar que saiu em silêncio antes de reiniciar. O `nofail` na coluna de
opções é a versão com cinto e suspensórios — ele deixa o boot continuar quando aquela montagem
falha, o que está certo para um disco de dados e errado para a raiz.

Assim que você chegar a um prompt, seja qual for:

```
journalctl -b -p err        # what failed this boot
systemctl --failed          # and what is still failing
systemctl list-jobs         # what is stuck waiting, right now
```

O `list-jobs` é o de uma travada: ele imprime as units que o systemd está esperando neste momento,
que é exatamente a pergunta.

## Dois jeitos de entrar quando não há prompt nenhum

**A linha de comando do kernel**, editada no carregador de boot na inicialização, aceita argumentos
do systemd:

| acrescente | te dá |
|---|---|
| `systemd.unit=rescue.target` | usuário único, shell de root, serviços mínimos |
| `systemd.unit=emergency.target` | menos que isso — raiz somente leitura, quase nada |
| `init=/bin/bash` | nenhum init. O último recurso |

**Uma imagem de resgate ou live** é o outro jeito, e o indicado para um sistema de arquivos raiz que
não monta. Dê boot nela, monte a raiz de verdade em algum lugar, e conserte o arquivo. O `mount` da
seção 12 da aula 3 é tudo de que você precisa.

Os dois valem ser lidos agora e tentados uma vez numa máquina que você pode quebrar. A tarde em que
você precisar deles não é a tarde de aprendê-los.
