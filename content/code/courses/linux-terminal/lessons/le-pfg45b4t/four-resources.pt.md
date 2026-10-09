---
title: Quatro recursos, e a diferença entre ocupado e travado
version: 2
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

## As ferramentas, e a carga que esta aula põe na máquina

O `vmstat`, o `free`, o `df` e o `top` vêm em todo Ubuntu. O `mpstat`, o
`iostat`, o `pidstat` e o `sar` são um pacote só, o `sysstat`, que algumas
instalações trazem e outras não. Se o `mpstat` responder `command not found`,
instale-o:

```sh
sudo apt install sysstat
```

Uma máquina sem fazer nada dá números sem nada para ler neles, então esta aula
cria dois tipos de trabalho de propósito, com dois scripts pequenos. O `spin.sh`
mantém todos os núcleos ocupados; o `fill.sh` escreve no disco o mais rápido que
ele aceitar. Os dois rodam até você pará-los:

```sh
mkdir -p ~/work/load && cd ~/work/load
cat > spin.sh <<'END'
#!/bin/bash
# One busy loop per core, until this script is stopped: pkill -f spin.sh
trap 'kill $(jobs -p); exit' TERM INT
for i in $(seq "$(nproc)"); do
  bash -c 'while :; do :; done' &
done
wait
END
cat > fill.sh <<'END'
#!/bin/bash
# Two writers, each rewriting a 1000 MB file in place, straight to the disk
# past the page cache (oflag=direct), until stopped: pkill -f fill.sh
trap 'kill $(jobs -p); exit' TERM INT
for i in 1 2; do
  bash -c "while :; do dd if=/dev/zero of=fill$i.tmp bs=1M count=1000 oflag=direct conv=notrunc status=none; done" &
done
wait
END
chmod +x spin.sh fill.sh
```

Cada seção diz quando iniciar um e quando pará-lo. O `fill.sh` precisa de dois
gigabytes livres e deixa os seus dois arquivos para você apagar.

## Utilização não é saturação

Esta é a distinção que torna os números legíveis, e é por que "100%" tantas
vezes não quer dizer nada.

**Utilização** é que fração do tempo o recurso esteve ocupado. Um processador a
100% de utilização está trabalhando, que é para isso que você o comprou.

**Saturação** é quanto trabalho está *esperando* porque o recurso está ocupado. É
esse o número que corresponde à requisição de alguém estar lenta.

Inicie os laços ocupados, dê alguns segundos a eles, e olhe:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ vmstat 1 4
procs -----------memory---------- ---swap-- -----io---- -system-- -------cpu-------
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st gu
 5  0      0 15704828   6896 371396    0    0   140 10094 1040    2  8  2 90  1  0  0
 4  0      0 15704828   6896 371396    0    0     0     0 1052  230 98  0  0  0  2  0
 4  0      0 15704576   6896 371396    0    0     0     0 1074  199 99  0  0  0  1  0
 4  0      0 15704576   6896 371396    0    0     0     0 1063  296 99  0  0  0  1  0
```

Aquilo é esta máquina com quatro laços ocupados em quatro núcleos. O `us 98` e o
`us 99` são **utilização** — os processadores estão inteiramente em uso, tirando
o um ou dois por cento em `st` que a seção 04 explica. O `r 4` é **saturação** —
tantos processos queriam um núcleo no momento da amostragem.

Quatro núcleos e quatro processos executáveis é uma máquina a todo vapor e
ninguém na fila. `r 40` em quatro núcleos seria a mesma utilização e um dia bem
diferente.

**Leia um número de utilização e um de saturação juntos, ou você vai confundir
uma máquina trabalhando com uma máquina quebrada.**

Deixe os laços rodando: a próxima seção começa vendo a carga média subir por
causa deles.

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

Tudo aqui foi capturado com a máquina genuinamente ocupada, pelos dois scripts
lá de cima: quatro laços girando em quatro núcleos e um gigabyte por segundo de
escrita num disco de verdade. Essa máquina tem quatro núcleos, 16 GB e nenhum
swap, e é um contêiner, o que uma seção transforma numa lição própria.

Duas seções precisaram do que ela não tem — grupos de controle do tipo atual, e
o `systemd` — e foram capturadas numa máquina virtual Ubuntu 24.04, a que a
aula 1 recomenda. Cada uma delas diz isso onde começa.

Onde um número não pôde ser produzido de jeito nenhum — swap em uso, numa
máquina sem swap — a seção diz isso em vez de colar um.
