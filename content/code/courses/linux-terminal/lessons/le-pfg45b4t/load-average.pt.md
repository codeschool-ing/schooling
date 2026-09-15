---
title: A carga média, que não é porcentagem e não é sobre o processador
version: 1
---

```
ana@vm:~$ uptime
 11:21:12 up  4:26,  0 user,  load average: 0.44, 0.14, 0.05
ana@vm:~$ cat /proc/loadavg
0.44 0.14 0.05 1/119 15413
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

A seção 89 nomeou esses dois estados. **O D é a parte que surpreende todo
mundo**, e é por que a carga média não é uma métrica de processador: uma máquina
com processador ocioso e disco saturado tem carga média alta, e uma máquina
usando todo núcleo sem nada na fila tem carga média igual à contagem de núcleos.

Outros Unixes fazem diferente. No Solaris e nos BSDs a carga média é só a fila de
execução, o que faz dela um número de processador lá e não aqui. Se você aprendeu
isso em outro sistema, desaprenda para o Linux.

## Compare com a contagem de núcleos

```
ana@vm:~$ uptime
 11:24:00 up  4:29,  0 user,  load average: 3.64, 1.66, 0.64
ana@vm:~$ nproc
4
```

Aquilo é esta máquina com quatro laços ocupados rodando. **3,64 em quatro
núcleos é uma máquina totalmente usada e sem fila.** Os mesmos 3,64 numa máquina
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

Aqui está esta máquina escrevendo um gigabyte por segundo no disco:

```
ana@vm:~$ uptime
 11:31:26 up  4:36,  0 user,  load average: 1.39, 1.20, 0.84
ana@vm:~$ vmstat 1 3
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 0  1      0 14476076  56304 1542856    0    0    69  5180  452    1  3  0 96  0  0  0
 0  1      0 14477244  56304 1542856    0    0     0 883716 3874 4433  6  5 67 22  0  0
 0  1      0 14485424  56304 1542856    0    0     0 980992 3815 4290  2  4 72 22  0  0
```

**Carga 1,39 numa máquina de quatro núcleos, e o disco a 93% de utilização.** Esse
93% é do `iostat`, na seção 184; o `vmstat` não o carrega. Só com a carga média
você fecharia o chamado. O `b 1` e o `wa 22` são a história de verdade, e são
lidos na seção 179 e na seção 184.

O contrário também acontece. Uma máquina emperrada num sistema de arquivos de
rede morto mostra carga média 40 com todo processador ocioso, porque quarenta
processos estão sentados em `D` esperando um servidor que não responde. Nada está
consumindo nada; nada vai terminar tampouco.

## O que usar no lugar

**A carga média é um alarme de fumaça, não um diagnóstico.** Ela te diz para
olhar, e então você olha outra coisa.

Se o seu kernel tiver — 4.20 em diante — há um número melhor:

```
ana@vm:~$ cat /proc/pressure/cpu; cat /proc/pressure/io
some avg10=0.00 avg60=0.00 avg300=0.05 total=106470752
full avg10=0.00 avg60=0.00 avg300=0.00 total=0
some avg10=9.49 avg60=16.67 avg300=6.54 total=92820647
full avg10=9.49 avg60=16.65 avg300=6.53 total=92436863
```

A **Pressure Stall Information** — PSI — é a porcentagem de tempo em que tarefas
ficaram *paradas* esperando cada recurso, ao longo de dez, sessenta e trezentos
segundos. O `some` é "ao menos uma tarefa estava parada"; o `full` é "todas
estavam".

Aqueles números foram tirados logo depois de o teste de disco acima terminar:
pressão de CPU essencialmente zero, pressão de I/O de 16,67% no último minuto.
**É uma leitura que diz ao mesmo tempo "não é o processador" e "é o disco", onde
a carga média dizia 1,39 e não queria dizer nada.**

O `/proc/pressure/memory` é o terceiro arquivo. Se eles não existirem, o kernel
foi compilado sem `CONFIG_PSI`, o que algumas distribuições ainda fazem.
