---
title: O processador, e as colunas que dizem para onde ele foi
version: 1
---

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

**O `vmstat 1` é o primeiro comando a rodar numa máquina de que alguém está
reclamando**, e a coisa mais importante sobre ele está na primeira linha.

## Jogue a primeira linha fora

Olhe a primeira linha: `us 1`, `id 97`. A máquina estava a 100% nas três linhas
abaixo, e a primeira diz que ela estava ociosa.

**A primeira linha do `vmstat` é uma média desde o boot.** O mesmo vale para o
primeiro bloco do `iostat`, e para a primeira linha do `sar`. Nada está errado;
você está lendo quatro horas e meia de história e confundindo com agora.

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
processos com valor de nice positivo, que é a prioridade da seção 97 aparecendo
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
é uma conversa com quem te vende a máquina. **Toda captura desta aula mostra
`st 0`**, porque nada aqui está disputado; não há forma honesta de produzir uma
figura de steal nesta máquina, então não há captura de uma.

## Por núcleo

Uma média esconde o caso que mais importa: uma thread cravada em 100% enquanto
sete núcleos ficam ociosos, o que dá média de 12,5% e parece ótimo.

```
ana@vm:~$ mpstat -P ALL 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:25:35     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
11:25:36     all  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       0  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       1  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       2  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
11:25:36       3  100.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00
```

Quatro laços, quatro núcleos, os quatro a 100%. **O `mpstat -P ALL 1` é como se
distingue uma máquina sem processador de um programa de uma thread só** — e o
segundo é muito mais comum que o primeiro.

O `%irq` e o `%soft` são tratamento de interrupção. `%soft` alto num núcleo só
normalmente é interrupção de rede não distribuída entre os núcleos.

## O `top`, para quando você quer uma tela só

```
ana@vm:~$ top -b -n 1 | head -12
top - 11:28:24 up  4:33,  0 user,  load average: 0.63, 1.42, 0.84
Tasks:  86 total,   4 running,  82 sleeping,   0 stopped,   0 zombie
%Cpu(s): 73.2 us,  0.0 sy,  0.0 ni, 24.4 id,  0.0 wa,  0.0 hi,  2.4 si,  0.0 st
MiB Mem :  16095.9 total,  14135.3 free,    652.0 used,   1558.0 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.  15443.9 avail Mem

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND
16258 ana       20   0    4720   3380   3080 R 100.0   0.0   0:04.21 bash
16259 ana       20   0    4720   3348   3048 R 100.0   0.0   0:04.20 bash
16260 ana       20   0    4720   3388   3088 R 100.0   0.0   0:04.21 bash
    1 root      20   0   26536   4240   3844 S   0.0   0.0   0:19.51 process_api
    2 root      20   0       0      0      0 S   0.0   0.0   0:00.01 kthreadd
```

A seção 92 tratou de ler o `top`. Duas coisas para esta aula:

**O `top -b -n 1` é a forma em lote** — uma tela, sem posicionamento de cursor —
que é o que você usa num script, por `ssh`, ou numa captura como esta.

**O `%CPU` é por núcleo, então passa de 100.** Um `%CPU` de 380 nesta máquina é
um processo usando quase os quatro núcleos; não é bug nem erro.

E a linha `Tasks: 86 total, 4 running` é a mesma contagem de que a carga média se
alimenta. O PID 1 ser o `process_api` e não o systemd é esta máquina ser um
sandbox, como a seção 77 explicou — os números são reais, a lista de processos é
a deste contêiner.

## Quando é o processador

```sh
vmstat 1                    # is r above the core count, sustained
mpstat -P ALL 1             # is it every core, or one
pidstat -u 1                # which process
```

Três comandos, nessa ordem, e o próximo depois deles é o `perf top` — que é um
profiler e está além do escopo desta aula, mas é a resposta honesta para "qual
*linha de código*".
