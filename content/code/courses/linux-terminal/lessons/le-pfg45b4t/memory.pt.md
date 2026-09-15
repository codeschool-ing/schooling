---
title: Memória, e por que pouca memória livre é a cara da saúde
version: 1
---

```
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       657Mi        13Gi        11Mi       1.5Gi        15Gi
Swap:             0B          0B          0B
```

Seis colunas, e **duas delas são as de ler**: `used` e `available`. As outras
existem para ser mal compreendidas.

| | |
|---|---|
| `total` | o que o kernel enxerga |
| `used` | memória anônima: os dados dos próprios programas. **Consumo real** |
| `free` | memória que o kernel não pôs para uso nenhum. **Não é uma meta** |
| `shared` | tmpfs e segmentos compartilhados, contados dentro de `used` |
| `buff/cache` | conteúdo de arquivos que o kernel está segurando |
| `available` | **o que um programa novo conseguiria sem swap.** A que importa |

## O cache não é memória usada

Memória vazia não serve para ninguém, então o kernel a enche com o conteúdo dos
arquivos que você leu, caso você os leia de novo. Isso é o cache de páginas, e
ele aparece em `buff/cache`.

Veja acontecendo:

```
ana@vm:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16095         661       14125          11        1558       15434
ana@vm:~$ dd if=/dev/zero of=/home/ana/work/cache.tmp bs=1M count=600 2>&1 | tail -1
629145600 bytes (629 MB, 600 MiB) copied, 3.4391 s, 183 MB/s
ana@vm:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16095         668       13510          11        2173       15426
```

Seiscentos megabytes foram escritos num arquivo. O `buff/cache` subiu 615, e o
`free` **caiu** 615.

**E o `available` não se mexeu**: 15434 antes, 15426 depois — oito megabytes, que
é ruído.

É a aula inteira numa medição. **Os 600 MB não sumiram.** Eles estão segurando
uma cópia de um arquivo, e o kernel os devolve no instante em que um programa
pedir memória. O `available` sabe disso; o `free` não.

Apague o arquivo e o cache vai junto:

```
ana@vm:~$ rm -f /home/ana/work/cache.tmp; free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:           16095         647       14139          11        1558       15448
```

De volta a 1558, exatamente onde começou.

**Então: uma máquina com 200 MB livres e 30 GB de cache não está sem memória.**
Uma com 200 MB *disponíveis* está. Quem escreve scripts para "liberar memória"
descartando caches está deixando a máquina mais lenta e chamando isso de
manutenção.

O `echo 3 > /proc/sys/vm/drop_caches` existe, funciona, e é uma ferramenta de
depuração para repetibilidade de benchmark. Não é conserto de nada.

## Por processo

O `free` diz o total da máquina. O `ps` diz quem:

```
ana@vm:~$ ps -eo pid,%cpu,%mem,rss,comm --sort=-%cpu | head -6
  PID %CPU %MEM   RSS COMMAND
16260  100  0.0  3388 bash
16258 99.8  0.0  3380 bash
16259 99.6  0.0  3348 bash
  103  4.1  2.4 403252 claude
16257  0.3  0.0 11156 python3
```

| | |
|---|---|
| `VSZ` | tamanho **virtual** — tudo mapeado, inclusive o que nunca foi tocado |
| `RSS` | conjunto **residente** — páginas físicas de fato na memória |
| `%MEM` | o `RSS` como fração do total |

**O `RSS` é o número que as pessoas querem dizer e ele conta em dobro.**
Bibliotecas compartilhadas são contadas no `RSS` de todo processo que as mapeia,
então somar a coluna `RSS` de cem processos dá uma resposta maior que a máquina.

O `VSZ` é quase sem sentido em programas modernos — um runtime que reserva 32 GB
de espaço de endereçamento e toca 200 MB mostra `VSZ` de 32 GB e está usando 200
MB.

Para o número que não conta em dobro existe o `PSS` — conjunto residente
proporcional, que divide cada página compartilhada entre os processos que a
compartilham:

```
ana@vm:~$ grep -E 'Rss|Pss' /proc/self/smaps_rollup
Rss:                2224 kB
Pss:                 667 kB
Pss_Dirty:           152 kB
Pss_Anon:            152 kB
Pss_File:            515 kB
Pss_Shmem:             0 kB
SwapPss:               0 kB
```

**2224 kB residentes, 667 kB proporcionais.** A maior parte da memória residente
deste shell é a libc e o próprio binário, compartilhados com todo outro processo
da máquina, e o `Pss` cobra dele a parte justa. Some o `Pss` de todo processo e o
total é a verdade; some o `Rss` e não é.

## O `/proc/meminfo`, para quando o `free` não basta

```
ana@vm:~$ grep -E 'MemTotal|MemFree|MemAvailable|^Cached|^Buffers|SwapTotal' /proc/meminfo
MemTotal:       16482220 kB
MemFree:        14493656 kB
MemAvailable:   15809336 kB
Buffers:           56096 kB
Cached:          1458848 kB
SwapTotal:             0 kB
```

O `free` é um formatador para este arquivo. Mais duas linhas dele valem:

```
ana@vm:~$ grep -E '^Dirty|^Slab|^Writeback' /proc/meminfo
Dirty:               180 kB
Writeback:             0 kB
Slab:              81980 kB
WritebackTmp:          0 kB
```

| | |
|---|---|
| `Dirty` | páginas modificadas ainda não escritas no disco. Grande e crescendo quer dizer que o disco está atrasado |
| `Writeback` | páginas sendo escritas agora |
| `Slab` | estruturas do kernel — caches de inode e dentry. Pode ter gigabytes e é recuperável |

**O `Slab` enorme é o que parece vazamento e não é**, numa máquina que percorreu
um sistema de arquivos com milhões de arquivos.

## Quando é memória mesmo

Três sinais, em ordem de certeza:

| | |
|---|---|
| `available` caindo para zero | o de verdade |
| `si`/`so` do `vmstat` diferentes de zero | a máquina está fazendo swap. Próxima seção |
| processos sendo mortos | o kernel desistiu. Duas seções à frente |

E um que não é sinal: o `free` ser pequeno. Ele sempre é.
