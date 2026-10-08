---
title: Contadores, taxas e médias — os três jeitos de um número mentir
version: 2
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
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc pfifo_fast state UP mode DEFAULT group default qlen 1000
    link/ether 02:fc:00:00:00:01 brd ff:ff:ff:ff:ff:ff
    RX:  bytes packets errors dropped  missed   mcast
    1003499627  214187      0       6       0       0
    TX:  bytes packets errors dropped carrier collsns
     333317247  179302      0       0       0       0
```

**Um gigabyte recebido. Desde quando?** Desde que a interface subiu, três horas
atrás. O número não te diz nada sobre a rede estar ocupada agora, e
um número maior não quer dizer rede mais ocupada — quer dizer uptime maior.

O mesmo vale para o `/proc/stat`, o `/proc/PID/io`, o `/proc/diskstats` e toda
coluna de `errors` em qualquer lugar.

**Um contador só é útil como diferença.** Duas leituras, dez segundos de
distância, e subtrai. Que é exatamente o que o `vmstat 1`, o `iostat 1`, o
`sar 1` e o `pidstat 1` fazem por você, e por que todos recebem um intervalo.

## E é por isso que a primeira linha está errada

Com os laços ocupados rodando de novo:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15676488  10324 394340    0    0   137 17341 1053    2  9  2 88  1  0  0
 4  0      0 15676488  10324 394340    0    0     0     0 1040  134 99  0  0  0  1  0
 4  0      0 15676488  10324 394340    0    0     0     0 1029  112 99  0  0  0  1  0
 4  0      0 15676488  10324 394340    0    0     0     0 1051  216 99  0  0  0  1  0
```

A primeira linha diz `us 9, id 88` numa máquina cravada em 99%. **Ela não tem
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
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:50:49     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
13:50:50     all   98.75    0.00    0.25    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:50:50       0   97.03    0.00    0.99    0.00    0.00    0.00    1.98    0.00    0.00    0.00
13:50:50       1   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:50:50       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:50:50       3   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00

Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   98.75    0.00    0.25    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       0   97.03    0.00    0.99    0.00    0.00    0.00    1.98    0.00    0.00    0.00
Average:       1   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       3   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
```

```sh
cd ~/work/load
pkill -f spin.sh
```

A linha `all` é uma média sobre quatro núcleos. Aqui todo núcleo está entre 97 e 100%,
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
