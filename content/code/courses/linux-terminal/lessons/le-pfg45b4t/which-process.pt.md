---
title: Qual processo, que é a pergunta que você faz por último
version: 2
---

As quatro seções anteriores acham o **recurso**. Esta acha o **culpado**, e ela
vem por último de propósito: saber que um processo usa muito processador não te
diz nada até você saber que o processador é o problema.

## O `pidstat`

Com os laços ocupados rodando:

```sh
cd ~/work/load
./spin.sh &
sleep 5
```

```
ana@vm:~$ pidstat -u 1 1
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:50:24      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
13:50:25        0        85    0.99    0.00    0.00    0.00    0.99     0  claude
13:50:25     1001     13326   97.03    0.00    0.00    0.99   97.03     0  bash
13:50:25     1001     13327  100.00    0.00    0.00    0.00  100.00     2  bash
13:50:25     1001     13328   98.02    0.00    0.00    0.99   98.02     3  bash
13:50:25     1001     13329   99.01    0.00    0.00    0.99   99.01     1  bash

Average:      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
Average:        0        85    0.99    0.00    0.00    0.00    0.99     -  claude
Average:     1001     13326   97.03    0.00    0.00    0.99   97.03     -  bash
Average:     1001     13327  100.00    0.00    0.00    0.00  100.00     -  bash
Average:     1001     13328   98.02    0.00    0.00    0.99   98.02     -  bash
Average:     1001     13329   99.01    0.00    0.00    0.99   99.01     -  bash
```

**O `pidstat` é o `top` que você consegue ler num script.** Ele amostra num
intervalo, imprime linhas simples, e tem uma opção por recurso:

| | |
|---|---|
| `pidstat -u 1` | processador |
| `pidstat -r 1` | memória, e **falhas de página** |
| `pidstat -d 1` | disco |
| `pidstat -w 1` | trocas de contexto |
| `pidstat -t` | por **thread**, não por processo |

Quatro colunas acima valem nomear. O `%usr` e o `%system` separam o trabalho do
jeito que a seção 04 fez. O `%wait` é tempo em que o processo ficou **executável
e sem rodar** — esperando um núcleo — que é saturação por processo e não está no
`top`. E o `CPU` é em qual núcleo ele esteve por último.

O processo `claude` a 0,99% é esta máquina ser um sandbox, como a aula 6 seção 06
explicou: o PID 85 é o agente que conduz estas capturas, e ele está em toda
listagem de processos deste curso porque ele está genuinamente lá.

## Para disco

Troque os laços pelos escritores:

```sh
cd ~/work/load
pkill -f spin.sh
./fill.sh &
sleep 10
```

```
ana@vm:~$ pidstat -d 1 1
Linux 6.18.44-fc-v77 (vm)       10/07/26        _x86_64_        (4 CPU)

13:50:35      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
13:50:36     1001     13351      0.00 145996.04      0.00       0  dd
13:50:36     1001     13352      0.00 147009.90      0.00       0  dd

Average:      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
Average:     1001     13351      0.00 145996.04      0.00       0  dd
Average:     1001     13352      0.00 147009.90      0.00       0  dd
```

**Aquilo é o fim da investigação** da seção de I/O de disco: os dois processos
`dd` que os escritores do `fill.sh` estavam rodando naquele segundo. Rode de novo
e os shells em volta deles podem aparecer também, com centenas de megabytes por
segundo na conta, porque quando um filho termina o kernel soma o I/O dele à
conta do pai — e cada `dd` aqui vive cerca de um segundo.

| | |
|---|---|
| `kB_rd/s` `kB_wr/s` | de fato lidos do e escritos no dispositivo |
| `kB_ccwr/s` | escritas **canceladas** — sujadas e então apagadas ou truncadas antes da descarga |
| `iodelay` | tiques de relógio em que o processo ficou bloqueado em I/O |

O `kB_ccwr/s` é uma coluna estranha com um bom uso: um processo com muitas
escritas canceladas está criando e apagando arquivos, que é um padrão de arquivo
temporário e frequentemente um engano.

O `pidstat -d` precisa ler o `/proc/PID/io`, que para processos de outros usuários
exige privilégio. Como usuário comum você vê os seus.

E pare-os, que é a última carga de que esta aula precisa:

```sh
cd ~/work/load
pkill -f fill.sh
sleep 3
rm -f fill1.tmp fill2.tmp
```

## O `/proc/PID/io`

```
ana@vm:~$ cat /proc/self/io
rchar: 7088
wchar: 0
syscr: 10
syscw: 0
read_bytes: 0
write_bytes: 0
cancelled_write_bytes: 0
```

Estes são **contadores desde que o processo começou**, não taxas — a distinção de
que a próxima seção trata.

| | |
|---|---|
| `rchar` `wchar` | bytes que o processo pediu, inclusive os servidos do cache |
| `read_bytes` `write_bytes` | bytes que de fato foram ao dispositivo |
| `syscr` `syscw` | quantas **chamadas** de leitura e escrita |

**`rchar` muito acima de `read_bytes` quer dizer que o cache está fazendo o
trabalho dele.** O contrário é impossível; os dois iguais querem dizer que toda
leitura foi ao disco, o que para um banco de dados é esperado e para um servidor
web é problema.

E `syscr` enorme com `rchar` pequeno é um programa fazendo milhões de leituras
minúsculas, que é o padrão que aparece como `sy` no `vmstat` e se conserta com
buffer, não com um disco mais rápido.

## O `iotop`

O `iotop` é o `top` para disco, e na maioria das máquinas precisa de root porque
o kernel não informa o I/O de outros usuários a você.

```sh
iotop -o          # only processes actually doing I/O
iotop -b -n 3     # batch mode, three samples — for a script or an ssh session
iotop -a          # accumulated totals rather than rates
```

É a forma mais rápida de responder "o que está martelando o disco"
interativamente, e o `pidstat -d` é o de usar quando você quer a resposta num
arquivo.

## Quando nada é óbvio

Dois casos em que as ferramentas por processo não mostram nada e a máquina
continua ocupada.

**Threads do kernel.** O `kswapd` recuperando memória, o `jbd2` confirmando um
journal, o `kworker` fazendo descarga. Eles aparecem no `top` com nomes entre
colchetes e são o kernel fazendo trabalho *em nome de* processos que já
retornaram. I/O alto de `kworker` normalmente é descarga se pondo em dia.

**Algo que já saiu.** Um trabalho de cron que roda quatro segundos a cada minuto
não aparece numa amostra que você tirou entre execuções. Este é o argumento para
o `sar`, que coleta continuamente:

```sh
sar -u 1 3        # processor, live
sar -d -p         # disks, from today's collected history
sar -r -f /var/log/sysstat/sa15   # memory, from the 15th
```

**O `sar` lê história que foi gravada enquanto ninguém olhava**, que é a única
forma de responder "o que aconteceu às 3 da manhã". Ele precisa que o coletor do
`sysstat` tenha sido habilitado — `systemctl enable --now sysstat` — e habilitá-lo
depois do incidente ajuda no próximo e não neste.
