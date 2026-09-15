---
title: Qual processo, que é a pergunta que você faz por último
version: 1
---

As quatro seções anteriores acham o **recurso**. Esta acha o **culpado**, e ela
vem por último de propósito: saber que um processo usa muito processador não te
diz nada até você saber que o processador é o problema.

## O `pidstat`

```
ana@vm:~$ pidstat -u 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:25:38      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
11:25:39        0       103    0.99    0.99    0.00    0.99    1.98     3  claude
11:25:39     1001     15588   99.01    0.00    0.00    0.00   99.01     0  bash
11:25:39     1001     15589   99.01    0.00    0.00    0.99   99.01     1  bash
11:25:39     1001     15590   99.01    0.00    0.00    0.00   99.01     2  bash
11:25:39     1001     15591   98.02    0.00    0.00    1.98   98.02     3  bash
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
jeito que a seção 179 fez. O `%wait` é tempo em que o processo ficou **executável
e sem rodar** — esperando um núcleo — que é saturação por processo e não está no
`top`. E o `CPU` é em qual núcleo ele esteve por último.

O processo `claude` a 1,98% é esta máquina ser um sandbox, como a seção 91
explicou: o PID 103 é o agente que conduz estas capturas, e ele está em toda
listagem de processos deste curso porque ele está genuinamente lá.

## Para disco

```
ana@vm:~$ pidstat -d 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:31:35      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
11:31:36     1001     16494      0.00 512016.00      0.00       0  bash
11:31:36     1001     16495      0.00 512000.00      0.00       0  bash
11:31:36     1001     16650      0.00  38912.00      0.00       0  dd
11:31:36     1001     16651      0.00  36864.00      0.00       0  dd
```

**Aquilo é o fim da investigação** da seção de I/O de disco: dois shells
escrevendo 512 MB por segundo cada um, com os processos `dd` que eles lançaram
por baixo.

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
