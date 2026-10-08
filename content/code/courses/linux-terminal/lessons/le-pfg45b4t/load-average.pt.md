---
title: A carga média, que não é porcentagem e não é sobre o processador
version: 2
---

```
ana@vm:~$ uptime
 13:44:05 up  3:13,  0 user,  load average: 0.68, 0.57, 0.79
ana@vm:~$ cat /proc/loadavg
0.68 0.57 0.79 5/128 11037
```

Três números: a média de um minuto, de cinco e de quinze. O `/proc/loadavg`
acrescenta mais dois — **processos rodando / processos no total**, e o último id
de processo alocado.

## O que está sendo calculado

**No Linux, a carga média conta processos em dois estados:**

| | |
|---|---|
| **R** — executável | rodando num núcleo, ou esperando um |
| **D** — sono ininterruptível | esperando um disco, normalmente |

A aula 6 seção 04 nomeou esses dois estados. **O D é a parte que surpreende todo
mundo**, e é por que a carga média não é uma métrica de processador: uma máquina
com processador ocioso e disco saturado tem carga média alta, e uma máquina
usando todo núcleo sem nada na fila tem carga média igual à contagem de núcleos.

Outros Unixes fazem diferente. No Solaris e nos BSDs a carga média é só a fila de
execução, o que faz dela um número de processador lá e não aqui. Se você aprendeu
isso em outro sistema, desaprenda para o Linux.

## Compare com a contagem de núcleos

Dê dois minutos aos laços, para a média de um minuto ter tempo de alcançá-los:

```sh
cd ~/work/load
sleep 120
```

```
ana@vm:~$ uptime
 13:46:05 up  3:15,  0 user,  load average: 3.55, 1.71, 1.19
ana@vm:~$ nproc
4
```

Aquilo é esta máquina com quatro laços ocupados rodando. **3,55 em quatro
núcleos é uma máquina totalmente usada e sem fila.** Os mesmos 3,55 numa máquina
de um núcleo significariam três processos e meio esperando a vez para cada um
rodando.

Então a única leitura sensata é a razão:

| | |
|---|---|
| carga ≈ núcleos | totalmente usada, nada esperando |
| carga < núcleos | capacidade ociosa |
| carga ≫ núcleos | algo está na fila — mas *por quê* é outra pergunta |

Não há limiar. "Carga 8" numa máquina de 8 núcleos está ok; numa de 2 é
problema; numa com um mount NFS travado não é nem um nem outro, porque todo
processo bloqueado naquele mount é contado e nenhum deles está usando nada.

## Os três números são uma direção

As figuras de um, cinco e quinze minutos importam como forma e não como valores:

| | |
|---|---|
| `0.44, 0.14, 0.05` | subindo. Algo começou há pouco |
| `0.64, 1.66, 3.64` | caindo. Seja o que for, acabou |
| `3.6, 3.6, 3.6` | estável. É isto que a máquina faz |

**Ler um número e não os outros dois é como você é chamado por um pico que
terminou há quarenta minutos.**

## Onde ela engana feio

Pare os laços e inicie os escritores no lugar deles, e dê um minuto a eles:

```sh
cd ~/work/load
pkill -f spin.sh
./fill.sh &
sleep 60
```

Aqui está esta máquina escrevendo no disco o mais rápido que consegue:

```
ana@vm:~$ uptime
 13:47:05 up  3:16,  0 user,  load average: 2.63, 1.78, 1.25
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 2  2      0 15720020   6984 371684    0    0   137 14442 1053    2  9  2 89  1  0  0
 2  1      0 15719940   6984 371684    0    0     0 1014784 3900 4669  1 10 52 37  1  0
 1  2      0 15719940   6984 371684    0    0     0 453632 1973 2351  0  5 53 41  0  0
```

**Carga 2,63 numa máquina de quatro núcleos, e o disco a 99,8% de utilização.** Esse
99,8% é do `iostat`, da seção 09 desta aula; o `vmstat` não o carrega. Só com a
carga média você fecharia o chamado. O `b 2` e o `wa 41` são a história de
verdade, e são lidos nas seções 04 e 09.

O contrário também acontece. Uma máquina emperrada num sistema de arquivos de
rede morto mostra carga média 40 com todo processador ocioso, porque quarenta
processos estão sentados em `D` esperando um servidor que não responde. Nada está
consumindo nada; nada vai terminar tampouco.

## O que usar no lugar

**A carga média é um alarme de fumaça, não um diagnóstico.** Ela te diz para
olhar, e então você olha outra coisa.

Se o seu kernel tiver — 4.20 em diante — há um número melhor. Pare os
escritores antes, e leia logo em seguida:

```sh
cd ~/work/load
pkill -f fill.sh
```

```
ana@vm:~$ cat /proc/pressure/cpu; cat /proc/pressure/io
some avg10=0.00 avg60=0.08 avg300=0.16 total=449522901
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
some avg10=59.63 avg60=37.54 avg300=12.06 total=146273944
full avg10=57.72 avg60=36.32 avg300=11.65 total=137359071
```

A **Pressure Stall Information** — PSI — é a porcentagem de tempo em que tarefas
ficaram *paradas* esperando cada recurso, ao longo de dez, sessenta e trezentos
segundos. O `some` é "ao menos uma tarefa estava parada"; o `full` é "todas
estavam".

Aqueles números foram tirados logo depois de o teste de disco acima terminar:
pressão de CPU essencialmente zero, pressão de I/O de 37,54% no último minuto.
**É uma leitura que diz ao mesmo tempo "não é o processador" e "é o disco", onde
a carga média dizia 2,63 e não queria dizer nada.**

O `/proc/pressure/memory` é o terceiro arquivo. Se eles não existirem, o kernel
foi compilado sem `CONFIG_PSI`, o que algumas distribuições ainda fazem.
