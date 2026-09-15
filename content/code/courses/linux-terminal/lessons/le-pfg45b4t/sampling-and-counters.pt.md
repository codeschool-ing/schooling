---
title: Contadores, taxas e médias — os três jeitos de um número mentir
version: 1
---

Todo número desta aula é uma de três coisas, e ler uma como outra é como uma
figura perfeitamente correta dá uma resposta errada.

| | |
|---|---|
| um **contador** | total desde o boot. Só diferenças querem dizer algo |
| uma **taxa** | um contador, dividido pelo tempo entre duas amostras |
| um **medidor** | o valor agora |

## Contadores

```
ana@vm:~$ ip -s link show eth0
…
    RX:  bytes packets errors dropped  missed   mcast
     365057734  262464      0       6       0       0
```

**365 megabytes recebidos. Desde quando?** Desde que a interface subiu, quatro
horas e meia atrás. O número não te diz nada sobre a rede estar ocupada agora, e
um número maior não quer dizer rede mais ocupada — quer dizer uptime maior.

O mesmo vale para o `/proc/stat`, o `/proc/PID/io`, o `/proc/diskstats` e toda
coluna de `errors` em qualquer lugar.

**Um contador só é útil como diferença.** Duas leituras, dez segundos de
distância, e subtrai. Que é exatamente o que o `vmstat 1`, o `iostat 1`, o
`sar 1` e o `pidstat 1` fazem por você, e por que todos recebem um intervalo.

## E é por isso que a primeira linha está errada

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

A primeira linha diz `us 1, id 97` numa máquina cravada em 100%. **Ela não tem
amostra anterior da qual subtrair, então divide o contador pelo uptime** e
imprime a média desde o boot.

Isso vale para o `vmstat`, o `iostat`, o `sar` e o `mpstat`, e é a leitura errada
mais comum em trabalho de desempenho. Dois hábitos consertam para sempre:

```sh
vmstat 1 5 | tail -4         # drop the first
iostat -xz 2 2 | tail -6     # same
```

**E nunca rode esses sem intervalo.** O `vmstat` sozinho imprime exatamente a
linha inútil e mais nada.

## Médias escondem o que você procura

Uma média de cinco minutos não consegue mostrar uma travada de dois segundos, e
uma travada de dois segundos é do que o usuário reclamou.

```
ana@vm:~$ mpstat -P ALL 1 1
…
11:25:36     all  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       0  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
```

A linha `all` é uma média sobre quatro núcleos. Aqui todo núcleo está a 100%,
então a média é honesta — mas **um núcleo a 100% e três ociosos dão média de
25%**, e essa é a forma mais comum de um problema real: um programa sem threads,
numa máquina com bastante capacidade sobrando.

O mesmo esconder acontece no tempo além de entre núcleos:

| | |
|---|---|
| `sar` no padrão | uma amostra a cada dez minutos. Não vê nada menor |
| `vmstat 1` | uma por segundo. Vê uma travada de dois segundos |
| `vmstat 5` | uma a cada cinco. **Pode perdê-la inteira** |

**Amostre na escala de tempo da reclamação.** "Ele trava um segundo a cada
minuto" precisa de `vmstat 1` por dois minutos, não de `sar` por uma hora.

## Percentis, onde você conseguir

Uma latência média de 5 ms com um percentil 99 de 4 segundos é um sistema em que
uma requisição em cada cem é inutilizável e a média diz que está tudo bem.

As ferramentas de linha de comando desta aula te dão médias — o `await` é uma
média. O `iostat -x` não tem percentil, e o `vmstat` também não. **Esse é um
limite real deste toolkit inteiro**, e a resposta honesta para "a cauda está
ruim" é ou métricas da aplicação, ou os histogramas do `bpftrace`, ou o `perf`.

O que vale dizer sem rodeios: estas ferramentas acham *qual recurso* e *qual
processo*. Para *qual requisição*, você precisa de instrumentação que já estava
lá antes do incidente.

## O que gravar antes de precisar

O argumento para o coletor do `sar`, numa frase: **você não consegue amostrar o
passado.**

```sh
systemctl enable --now sysstat        # collect every ten minutes, keep a month
sar -u -f /var/log/sysstat/sa15       # processor, on the 15th
sar -d -p -f /var/log/sysstat/sa15    # disks, with real names
sar -n DEV -f /var/log/sysstat/sa15   # network
```

Dez minutos de granularidade é grosseiro e é infinitamente melhor que nada às
três da manhã, quando a máquina está saudável de novo e ninguém sabe dizer o que
ela estava fazendo.
