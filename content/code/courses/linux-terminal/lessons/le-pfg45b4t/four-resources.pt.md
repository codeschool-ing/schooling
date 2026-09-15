---
title: Quatro recursos, e a diferença entre ocupado e travado
version: 1
---

"A máquina está lenta" não é um relato. Vira um quando você consegue dizer qual
das quatro coisas acabou.

| | medido com | |
|---|---|---|
| **processador** | `vmstat`, `mpstat`, `top` | há algo esperando um núcleo |
| **memória** | `free`, `/proc/meminfo` | há algo esperando uma página |
| **espaço em disco** | `df`, `du` | há lugar para escrever |
| **vazão de disco** | `iostat`, `vmstat` | há algo esperando uma leitura ou escrita |

A rede é um quinto e se comporta como o quarto — é um dispositivo com fila —
então ela ganha uma seção própria mas não uma ideia nova.

**Quase todo problema de desempenho é um desses quatro**, e a habilidade é
perguntá-los em ordem e parar quando um responder, em vez de coletar todo número
que você sabe coletar.

## Utilização não é saturação

Esta é a distinção que torna os números legíveis, e é por que "100%" tantas
vezes não quer dizer nada.

**Utilização** é que fração do tempo o recurso esteve ocupado. Um processador a
100% de utilização está trabalhando, que é para isso que você o comprou.

**Saturação** é quanto trabalho está *esperando* porque o recurso está ocupado. É
esse o número que corresponde à requisição de alguém estar lenta.

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 4  0      0 14507736  56092 1514136    0    0    71   358  431    1  3  0 97  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1074  218 100  0  0  0  0  0
 5  0      0 14507736  56092 1514136    0    0     0     0 1062  188 100  0  0  0  0  0
 4  0      0 14507736  56092 1514136    0    0     0     0 1083  296 100  0  0  0  0  0
```

Aquilo é esta máquina com quatro laços ocupados em quatro núcleos. O `us 100` é
**utilização** — os processadores estão inteiramente em uso. O `r 4` e o `r 5` é
**saturação** — tantos processos queriam um núcleo no momento da amostragem.

Quatro núcleos e quatro processos executáveis é uma máquina a todo vapor e
ninguém na fila. `r 40` em quatro núcleos seria a mesma utilização e um dia bem
diferente.

**Leia um número de utilização e um de saturação juntos, ou você vai confundir
uma máquina trabalhando com uma máquina quebrada.**

## Erros são a terceira coisa

A lista completa — a de Brendan Gregg, que vale conhecer pelo nome, o **método
USE** — é: para todo recurso, confira **Utilização, Saturação e Erros**.

Erros são os que ninguém olha até muito depois do que deveria:

```sh
ip -s link show eth0              # RX/TX errors and drops
dmesg -T | grep -iE 'error|fail'  # the kernel's own complaints
cat /proc/net/dev                 # the same counters, raw
```

Uma placa de rede descartando um pacote em dez mil não aparece como utilização
nem como saturação em lugar nenhum. Ela aparece como uma aplicação que é
ocasionalmente, irreprodutivelmente lenta.

## O único número que não está na lista

Não existe um número de "a máquina está lenta", e o que as pessoas pegam — a
**carga média** — é a figura mais mal lida de um sistema Linux. É a próxima
seção, e vem primeiro porque você precisa desaprendê-la antes que o resto ajude.

## Em que esta aula mede

Tudo aqui foi capturado nesta máquina enquanto ela estava genuinamente ocupada:
quatro processos girando em quatro núcleos, um gigabyte por segundo de escrita
num disco de verdade, e um programa passando de um limite de cem megabytes até o
kernel matá-lo.

Onde um número não pôde ser produzido aqui — o `%steal`, que precisa de um
hipervisor sobrecarregado — a seção diz isso em vez de colar um.
