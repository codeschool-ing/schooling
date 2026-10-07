---
title: O processador, e as colunas que dizem para onde ele foi
version: 2
---

Inicie os laços ocupados de novo:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15719688   6984 371660    0    0   137 14614 1053    2  9  2 89  1  0  0
 4  0      0 15719516   6984 371660    0    0     0     0 1030  202 100  0  0  0  1  0
 4  0      0 15719436   6984 371660    0    0     0     0 1045  231 99  0  0  0  1  0
 4  0      0 15719436   6984 371660    0    0     0     0 1052  245 99  0  0  0  1  0
```

**O `vmstat 1` é o primeiro comando a rodar numa máquina de que alguém está
reclamando**, e a coisa mais importante sobre ele está na primeira linha.

## Jogue a primeira linha fora

Olhe a primeira linha: `us 9`, `id 89`. A máquina estava a 99% nas três linhas
abaixo, e a primeira diz que ela estava ociosa.

**A primeira linha do `vmstat` é uma média desde o boot.** O mesmo vale para o
primeiro bloco do `iostat`, e para a primeira linha do `sar`. Nada está errado;
você está lendo três horas de história e confundindo com agora.

Esta é a leitura errada mais comum desta aula, e o conserto é mecânico: **rode
com um intervalo e ignore a primeira amostra.**

## As colunas que valem

| | |
|---|---|
| `r` | processos **executáveis** — num núcleo ou esperando um |
| `b` | processos **bloqueados**, em sono ininterruptível |
| `si` `so` | páginas trazidas **para** e mandadas **da** memória por segundo |
| `bi` `bo` | blocos lidos de e escritos em dispositivos por segundo |
| `in` `cs` | **interrupções** e **trocas de contexto** por segundo |

O `r` contra a contagem de núcleos é o número de saturação que a carga média não
é: `r 4` em quatro núcleos é cheio, `r 40` é fila.

O `cs` merece um olhar. Nesta máquina, com laços ocupados, ele fica em cerca de
200 por segundo. Uma máquina fazendo dezenas de milhares de trocas de contexto
por segundo está gastando o tempo mudando de ideia, o que normalmente é threads
demais ou um lock que todo mundo quer.

## As colunas de CPU

```
us sy id wa st gu
```

| | |
|---|---|
| `us` | **usuário** — o código dos seus próprios programas |
| `sy` | **sistema** — o kernel, em nome deles. Syscalls, falhas de página |
| `id` | **ocioso** — nada para rodar |
| `wa` | **iowait** — ocioso, *e* ao menos uma tarefa bloqueada em disco |
| `st` | **roubado** — o hipervisor deu a sua fatia para outro |
| `gu` | **convidado** — tempo rodando uma máquina virtual, se esta for um host |

O `top` e o `mpstat` separam mais uma, o `ni` — tempo de usuário gasto por
processos com valor de nice positivo, que é a prioridade da aula 6 seção 12 aparecendo
como coluna.

Três destas valem ler com cuidado.

**`sy` alto com `us` baixo** quer dizer que o kernel está fazendo o trabalho:
leituras pequenas demais, processos demais sendo criados, uma syscall num laço
apertado. O `strace -c` no processo nomeia a syscall.

**O `wa` não é uma medida de carga de disco.** Ele é tempo ocioso que aconteceu
enquanto algo esperava o disco. Uma máquina com `wa 50` e um processo bloqueado
pode estar perfeitamente saudável; uma com `wa 0` pode ter um disco saturado se
os processadores estiverem ocupados o bastante para não sobrar tempo ocioso para
atribuir. O `wa` é uma dica para olhar o `iostat`, não um veredito.

**O `st` é o que você não consegue consertar.** Ele quer dizer que você está numa
máquina virtual e o host está sobrecarregado — o seu tempo de processador está
sendo dado a outro inquilino. Qualquer coisa acima de alguns por cento sustentada
é uma conversa com quem te vende a máquina. **As capturas desta aula mostram
`st` em 1 ou 2 enquanto os laços rodam**, porque esta máquina é ela mesma uma
máquina virtual num host compartilhado, e um pouco do tempo dela está indo para
outro lugar. Essa é a ponta inofensiva da escala; a mesma coluna em 20 é a carga
de outra pessoa deixando a sua mais lenta.

## Por núcleo

Uma média esconde o caso que mais importa: uma thread cravada em 100% enquanto
sete núcleos ficam ociosos, o que dá média de 12,5% e parece ótimo.

```
ana@vm:~$ mpstat -P ALL 1 1
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:47:15     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
13:47:16     all   99.50    0.00    0.00    0.00    0.00    0.00    0.50    0.00    0.00    0.00
13:47:16       0   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
13:47:16       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:47:16       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
13:47:16       3   99.01    0.00    0.00    0.00    0.00    0.00    0.99    0.00    0.00    0.00

Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all   99.50    0.00    0.00    0.00    0.00    0.00    0.50    0.00    0.00    0.00
Average:       0   99.00    0.00    0.00    0.00    0.00    0.00    1.00    0.00    0.00    0.00
Average:       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
Average:       3   99.01    0.00    0.00    0.00    0.00    0.00    0.99    0.00    0.00    0.00
```

Quatro laços, quatro núcleos, cada um com 99 a 100% de tempo de usuário, e o que
sobra é `%steal`, a coluna do parágrafo anterior. **O `mpstat -P ALL 1` é como se
distingue uma máquina sem processador de um programa de uma thread só** — e o
segundo é muito mais comum que o primeiro.

O `%irq` e o `%soft` são tratamento de interrupção. `%soft` alto num núcleo só
normalmente é interrupção de rede não distribuída entre os núcleos.

## O `top`, para quando você quer uma tela só

```
ana@vm:~$ top -b -n 1 | head -12
top - 13:40:26 up  3:10,  0 user,  load average: 1.20, 0.85, 0.94
Tasks:  98 total,   5 running,  92 sleeping,   0 stopped,   1 zombie
%Cpu(s): 95.5 us,  2.3 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  2.3 st
MiB Mem :  16094.7 total,  15378.4 free,    681.0 used,    310.6 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15413.7 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
 9684 ana       20   0    4764   3384   3124 R  90.9   0.0   0:05.12 bash
 9685 ana       20   0    4764   3376   3120 R  90.9   0.0   0:05.15 bash
 9687 ana       20   0    4764   3360   3108 R  90.9   0.0   0:05.11 bash
 9686 ana       20   0    4764   3412   3156 R  81.8   0.0   0:05.03 bash
  102 root      20   0 2097272  42988  27820 S   9.1   0.3   0:08.87 environment-man
```

A aula 6 seção 07 tratou de ler o `top`. Duas coisas para esta aula:

**O `top -b -n 1` é a forma em lote** — uma tela, sem posicionamento de cursor —
que é o que você usa num script, por `ssh`, ou numa captura como esta.

**O `%CPU` é por núcleo, então passa de 100.** Um `%CPU` de 380 nesta máquina é
um processo usando quase os quatro núcleos; não é bug nem erro.

E a linha `Tasks: 98 total, 5 running` é a mesma contagem de que a carga média se
alimenta: quatro laços e o próprio `top`. O `environment-man` lá embaixo é esta
máquina ser um sandbox, como a aula 5 seção 08 explicou — os números são reais, a
lista de processos é a deste contêiner.

## Quando é o processador

```sh
vmstat 1                    # is r above the core count, sustained
mpstat -P ALL 1             # is it every core, or one
pidstat -u 1                # which process
```

Três comandos, nessa ordem, e o próximo depois deles é o `perf top` — que é um
profiler e está além do escopo desta aula, mas é a resposta honesta para "qual
*linha de código*".

Pare os laços:

```sh
cd ~/work/load
pkill -f spin.sh
```
