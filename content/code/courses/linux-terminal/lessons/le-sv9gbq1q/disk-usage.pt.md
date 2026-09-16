---
title: O que está ocupando o espaço
version: 1
---

Dois comandos, e eles respondem duas perguntas diferentes que as pessoas esperam que concordem.

| | pergunta | responde |
|---|---|---|
| `df` | *quão cheio está este **sistema de arquivos**?* | perguntando ao sistema de arquivos |
| `du` | *quanto espaço estes **arquivos** usam?* | somando os arquivos que ele consegue ver |

Eles discordam mais do que se imagina, e cada uma das discordâncias vale entender, porque cada uma
é um modo de falha real.

## `df`: quão cheio está

```
ana@vm:~/work$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

`-h` para legível por humanos, sempre. Dê um caminho e ele responde sobre o sistema de arquivos em
que aquele caminho está — então `df -h .` é o jeito mais rápido de perguntar "estou prestes a ficar
sem espaço *aqui*".

**Size, Used e Avail não fecham a conta, e isso é normal.** 11 usados mais 27 disponíveis não são
252. Numa instalação ext4 comum a diferença é pequena e tem uma causa principal: **5% do sistema de
arquivos é reservado para o root**, para que um disco cheio para todo mundo ainda deixe ao
administrador espaço para entrar e consertar. É também por isso que o `Use%` é calculado contra o
que *você* pode usar, e não contra o `Size`.

A diferença nesta máquina é muito maior que 5%, porque ela é uma máquina virtual cujo disco carrega
uma reserva definida fora do sistema de arquivos. Vale conhecer como forma: em hospedagens de nuvem
e em contêineres, o `Size` é frequentemente o tamanho de algo maior do que você tem direito de
encher.

### O segundo jeito de um disco encher

```
ana@vm:~/work$ df -i /
Filesystem       Inodes  IUsed    IFree IUse% Mounted on
/dev/vda       16777216 210406 16566810    2% /
```

`-i` conta **inodes** em vez de bytes. A seção 11 apresentou: um por arquivo, e um sistema de
arquivos é criado com uma quantidade fixa deles.

Então um sistema de arquivos pode estar 4% cheio e ainda assim se recusar a criar um arquivo,
porque acabaram os inodes — milhões de arquivinhos de sessão, ou um cache que ninguém nunca podou.
O sintoma é `No space left on device` com um `df -h` de aparência tranquila, e a resposta é `df -i`.

**Confira os dois.** É a primeira coisa a fazer quando um disco está "cheio" e não parece.

## `du`: o que está usando

```
ana@vm:~/work$ du -sh
472K    .
```

`-s` para um resumo em vez de uma linha por diretório, `-h` para legível. O idiom que você vai
digitar de verdade é este:

```
ana@vm:~/work$ du -sh * | sort -h
4.0K    Makefile
4.0K    README.md
12K     data
16K     logs
16K     notes
16K     src
396K    build
```

**`du -sh * | sort -h`, depois `cd` no maior e repita.** É assim que se diagnostica um disco cheio,
e leva umas quatro rodadas para caminhar de `/` até o diretório de fato responsável. O `sort -h`
entende `K`, `M` e `G`, coisa que o `sort` simples não faz.

`--max-depth` é a mesma caminhada sem o `cd`:

```
ana@vm:~/work$ du -h --max-depth=1 | sort -h
12K     ./data
16K     ./logs
16K     ./notes
16K     ./src
396K    ./build
472K    .
```

**Rode `du` em `/` e você vai esperar**, porque ele percorre todo arquivo da máquina. Num servidor
grande comece por `/var` — que é onde as coisas crescem — e ponha `2>/dev/null` no fim, pelo mesmo
motivo que o `find` precisou na seção 09.

## Por que os números nunca são bem os tamanhos

```
ana@vm:~/work$ ls -l logs/app.log
-rw-r--r-- 1 ana ana 440 Mar 26  2025 logs/app.log
ana@vm:~/work$ du -sh logs/app.log
4.0K    logs/app.log
```

440 bytes, e quatro kilobytes de disco. **Um sistema de arquivos aloca espaço em blocos**, de 4 KiB
aqui, e um arquivo recebe blocos inteiros preencha-os ou não. Um arquivo de 1 byte custa 4 KiB, e
um diretório com dez mil arquivinhos custa quarenta megabytes para guardar algumas centenas de
kilobytes de conteúdo.

Essa é a diferença entre *tamanho* e *espaço*, e o `du` te mostra qualquer um dos dois:

```
ana@vm:~/work$ du --apparent-size -sh logs/app.log
440     logs/app.log
```

O `du` conta disco. O `ls -l` e o `du --apparent-size` contam conteúdo. **O `du` é quem está certo
sobre o disco estar cheio**, e é por isso que ele é o padrão.

O mesmo vale para um diretório: `ls -ld data` diz `4096` — o tamanho da lista de nomes dele —
enquanto `du -sh data` diz `12K`, que é essa lista mais tudo que ela nomeia.

## O que gasta uma tarde: apagado, e ainda lá

```
root@vm:/root# dd if=/dev/zero of=/mnt/backups/big.bin bs=1M count=30 status=none
root@vm:/root# tail -f /mnt/backups/big.bin > /dev/null &
root@vm:/root# rm /mnt/backups/big.bin
root@vm:/root# du -sh /mnt/backups
24K     /mnt/backups
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   31M   22M  59% /mnt/backups
```

Um arquivo de 30 MB foi criado, um programa foi deixado lendo, e ele foi apagado. Agora **o `du`
diz 24 KB e o `df` diz que 31 MB estão em uso**, no mesmo sistema de arquivos, no mesmo instante.
Os dois estão falando a verdade.

A seção 11 explicou por quê. O `rm` remove um *nome*. Os dados ficam até a última referência sumir
— e um descritor de arquivo aberto é uma referência, exatamente como um nome é. O `du` percorre
nomes, então não tem como ver este arquivo. O sistema de arquivos conta blocos, então tem.

O `lsof` acha:

```
root@vm:/root# lsof /mnt/backups 2>/dev/null
COMMAND  PID USER   FD   TYPE DEVICE SIZE/OFF NODE NAME
tail    1929 root    3r   REG    7,0 31457280   14 /mnt/backups/big.bin (deleted)
```

Ali está, com `(deleted)` depois do nome e os 31457280 bytes ainda contando. Pare o processo e o
espaço volta sozinho:

```
root@vm:/root# kill %1
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   28K   52M   1% /mnt/backups
```

**Este é de longe o "apaguei os logs e não aconteceu nada" mais comum.** Um serviço estava com o
arquivo de log aberto, alguém apagou o arquivo em vez de esvaziá-lo, e o disco continuou cheio até
o serviço ser reiniciado. O conserto certo é esvaziar em vez de remover:

```
: > /var/log/huge.log
```

Isso trunca para zero enquanto o programa continua escrevendo no mesmo arquivo aberto. O
`logrotate` da aula 5 é a versão disso que roda sozinha.

## As outras três discordâncias, nomeadas

**Uma montagem embaixo.** `du /mnt` conta o que está dentro de qualquer coisa montada ali abaixo;
`df /mnt` responde só sobre o sistema de arquivos do próprio `/mnt`. `du -x` fica num sistema de
arquivos só, que normalmente é o que você quis dizer.

**Arquivos que você não vê.** O `du` como usuário comum pula em silêncio os diretórios que não pode
ler, então o total dele sai baixo. Um `du` que importa é um `du` rodado com `sudo`.

**Hard links.** O `du` conta um inode uma vez, por mais nomes que cheguem nele. Essa é a resposta
certa, e quer dizer que o `du` em dois diretórios separadamente pode somar mais do que o `du` nos
dois juntos.
