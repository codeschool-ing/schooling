---
title: Um método, para quando alguém diz que a máquina está lenta
version: 1
---

Os comandos não são a habilidade. A ordem é.

## Sessenta segundos

Esta é a lista, na ordem que descarta coisas mais rápido. Cada linha é um
comando, e a maioria das investigações termina nos quatro primeiros.

```sh
uptime                  # 1. is anything queueing at all
dmesg -T | tail -20     # 2. did the kernel already tell you
vmstat 1 5              # 3. processor, memory, io — all three at once
mpstat -P ALL 1 3       # 4. one core or all of them
pidstat -u 1 3          # 5. which process, for processor
iostat -xz 2 3          # 6. which disk, and is await bad
free -m                 # 7. is available falling
sar -n DEV 1 3          # 8. is the network moving
ss -s                   # 9. are sockets piling up
```

**Os passos 1 a 4 te dizem qual dos quatro recursos é.** Os passos 5 a 9 são o
seguimento para o que respondeu, e você não roda os outros.

O passo 2 é o que as pessoas pulam e é de graça. Uma morte por OOM, um erro de
disco, um sistema de arquivos remontado somente leitura, uma placa de rede
reiniciando — o kernel já anotou, e olhar leva três segundos.

## A decisão, escrita

| o que você vê | o que é | para onde ir |
|---|---|---|
| `r` > núcleos, `us` alto | processador, em código de usuário | `pidstat -u`, e então um profiler |
| `r` > núcleos, `sy` alto | processador, no kernel | `pidstat -u`, e então `strace -c` |
| `wa` alto, `b` > 0, `r` baixo | **disco** | `iostat -xz`, e então `pidstat -d` |
| `si`/`so` agitados | memória, fazendo swap | `ps --sort=-rss`, ache o que cresce |
| `available` perto de zero | memória | o mesmo, e confira o `dmesg` por mortes |
| `st` diferente de zero | o host está sobrecarregado | não é seu para consertar |
| tudo ocioso, ainda lento | **não é esta máquina** | rede, uma dependência, um lock |

**Aquela última linha é a mais importante.** Uma máquina com quatro núcleos
ociosos, memória livre e disco quieto não é o problema, e cada minuto gasto
olhando mais para ela é um minuto não gasto no banco de dados que ela está
esperando.

## Quatro perguntas antes de tudo isso

**Quando começou?** Uma mudança às 14h05 e um incidente às 14h06 é outra
investigação que uma que degrada há um mês.

**É tudo ou uma coisa só?** Um endpoint lento é um problema de aplicação
fantasiado de desempenho.

**É esta máquina?** Veja acima. Um `ss -ti`, um `curl -w` contra a dependência,
ou um `ping` te dizem num comando.

**O que mudou?** Um deploy, um envio de configuração, um trabalho de cron, um
certificado que expirou, um disco que encheu. Problemas de desempenho que
aparecem sem causa são raros; problemas de desempenho cuja causa ninguém
mencionou não são.

## Conserte a medição antes da máquina

Duas armadilhas, e as duas desperdiçam um dia.

**Não ajuste nada que você não mediu.** Todo `sysctl` de um post de blog era a
resposta certa para a carga de outra pessoa. O `vm.swappiness`, o
`vm.dirty_ratio`, o escalonador, o tamanho de readahead — cada um deles é um
botão real e cada um é uma forma de piorar a máquina se você estiver adivinhando.

**Não conserte o sintoma.** Um disco enchendo não se conserta apagando logs; se
conserta descobrindo por que eles cresceram. O `df` a 95% é um prazo, não um
diagnóstico.

## O resumo de uma linha da aula

| | |
|---|---|
| carga média | **não é porcentagem**, conta quem espera disco, compare com núcleos |
| `free` | **pouco livre é saudável**, leia o `available` |
| `%util` | **não é saturação** em nada com fila, leia o `await` |
| a primeira linha | **é média desde o boot**, no `vmstat`, no `iostat` e no `sar` |
| dentro de um contêiner | **todos eles leem o host**, confira o cgroup |

Essas cinco frases são todo o propósito desta aula. Os comandos você consulta.
