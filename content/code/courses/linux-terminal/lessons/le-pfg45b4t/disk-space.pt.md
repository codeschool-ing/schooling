---
title: Espaço em disco, e três jeitos de um disco cheio não estar cheio
version: 2
---

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   29G  28% /
```

Leia aquela linha com cuidado. **252 gigabytes no total, 11 usados, 29
disponíveis — e 11 mais 29 não dá 252.**

Isso não é bug e é a primeira coisa a entender sobre o `df`:

```
ana@vm:~$ stat -f / | head -6
  File: "/"
    ID: ea3c3688a915b271 Namelen: 255     Type: ext2/ext3
Block size: 4096       Fundamental block size: 4096
Blocks: Total: 66053021   Free: 63275800   Available: 7433682
Inodes: Total: 16777216   Free: 16531303
```

**`Free` e `Available` são números diferentes.** 63 milhões de blocos não estão
em uso; 7,4 milhões deles estão disponíveis *para você*. O resto é reservado — por
padrão o ext4 guarda 5% para o `root`, para que um disco cheio não impeça a
máquina de ser consertada, e nesta máquina uma cota reserva bem mais que isso.

E o `Use%` é calculado contra o que você pode usar, não contra o total:
11 / (11 + 29) dá 27,5%, que arredonda para os 28% da saída. **O `df` está te
dizendo a verdade sobre um número que você não pediu**, e no momento em que você
precisar que `Size` seja igual a `Used + Avail` você está com o modelo mental
errado.

O `tune2fs -m 1 /dev/sda1` muda a reserva para 1%, o que num disco de dados de
vários terabytes recupera uma quantidade útil e no sistema de arquivos raiz é uma
má ideia.

## Cheio com espaço livre

Isto precisa de um sistema de arquivos pequeno o bastante para encher, então crie
um dentro de um arquivo, como a aula 3 seção 12 fez, com pouquíssimos inodes — o
`-N 256` pede 256:

```sh
cd ~
truncate -s 32M small.img
mkfs.ext4 -q -N 256 small.img
sudo mkdir -p /mnt/small
sudo mount -o loop small.img /mnt/small
sudo chown ana:ana /mnt/small
```

```
ana@vm:/mnt/small$ df -h /mnt/small; df -i /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       28M   24K   26M   1% /mnt/small
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop1        256    11   245    5% /mnt/small
ana@vm:/mnt/small$ cd /mnt/small && for i in $(seq 1 300); do touch f$i 2>/dev/null; done; ls | wc -l
246
ana@vm:/mnt/small$ touch one-more
touch: cannot touch 'one-more': No space left on device
ana@vm:/mnt/small$ df -h /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       28M   24K   26M   1% /mnt/small
ana@vm:/mnt/small$ df -i /mnt/small
Filesystem     Inodes IUsed IFree IUse% Mounted on
/dev/loop1        256   256     0  100% /mnt/small
```

**`No space left on device`, com 26 megabytes livres e 1% usado.**

Aquilo é um sistema de arquivos construído com 256 inodes, um número
deliberadamente minúsculo para esta demonstração — o `mkfs.ext4 -N 256` é a única
coisa incomum aqui. Todo arquivo precisa de um inode seja qual for o tamanho,
então trezentos arquivos vazios acabaram com os inodes com os blocos de dados mal
tocados.

**`ENOSPC` quer dizer "sem espaço" e o `df -h` é só metade da pergunta.** Numa
máquina de verdade isto é uma fila de e-mail, um diretório de sessões ou um cache
de milhões de arquivinhos, e é uma das poucas falhas em que a mensagem de erro
aponta para exatamente o número errado.

O `df -i` é a outra metade, e olhar não custa nada.

## Cheio com o arquivo apagado

O segundo jeito, e o que mais desperdiça tempo. Esvazie o sistema de arquivos
pequeno, e crie um processo que faz o que uma rotação de log descuidada faz: ele
abre o `big.log`, escreve vinte megabytes nele, apaga-o, e continua rodando com o
arquivo ainda aberto, como descritor 9:

```sh
cd ~
rm -f /mnt/small/f* /mnt/small/one-more
bash -c 'exec 9> /mnt/small/big.log; head -c 20M /dev/zero >&9; rm /mnt/small/big.log; exec sleep 3600' &
sleep 1
```

Agora olhe o disco como alguém que não viu aquilo olharia:

```
ana@vm:~$ df -h /mnt/small
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop1       28M   21M  5.7M  78% /mnt/small
ana@vm:~$ du -sh /mnt/small
du: cannot read directory '/mnt/small/lost+found': Permission denied
20K     /mnt/small
ana@vm:~$ ls -la /mnt/small
total 24
drwxr-xr-x 3 ana  ana   4096 Oct  7 13:48 .
drwxr-xr-x 8 root root  4096 Oct  7 13:21 ..
drwx------ 2 root root 16384 Oct  7 13:48 lost+found
```

**O `df` diz que 21 megabytes estão usados. O `du` diz 20 kilobytes. O `ls` não
mostra nada.**

(O aviso do `du` não tem relação e é honesto: o `lost+found` é modo 700 do root,
então um usuário comum não consegue percorrê-lo. Ele está vazio.)

A resposta:

```
ana@vm:~$ lsof +L1 /mnt/small
COMMAND   PID USER   FD   TYPE DEVICE SIZE/OFF NLINK NODE NAME
sleep   13124  ana    9w   REG    7,1 20971520     0   12 /mnt/small/big.log (deleted)
```

**`NLINK 0` e `(deleted)`.** Um processo tem o arquivo aberto; alguém apagou o
nome; os dados não podem ser liberados até o último descritor fechar. Os links
físicos da aula 3 seção 11 e os descritores da aula 6 seção 13, se encontrando no lugar menos
conveniente.

O `lsof +L1` lista arquivos abertos com menos de um link — que é exatamente este
caso e nada mais.

**O conserto não é o `rm`**, porque não sobrou nada para remover. É reiniciar o
processo, ou, se você não puder, truncar o arquivo pelo descritor:

```sh
: > /proc/13124/fd/9        # the space comes back immediately
```

É o que acontece quando alguém rotaciona um log apagando-o em vez de usar o
`logrotate`: o disco continua cheio até o serviço ser reiniciado, e o `du` jura
que o espaço não está em uso.

Aqui, encerrar o processo é o reinício, e ele devolve o espaço. Depois o sistema
de arquivos pequeno pode ir embora:

```sh
cd ~
pkill -xf 'sleep 3600'
sudo umount /mnt/small
rm small.img
```

## Achar o espaço

```sh
du -sh /*                     # which top-level directory
du -h --max-depth=1 /var | sort -h    # then walk down
du -xh --max-depth=1 /        # -x stays on one filesystem
find / -xdev -size +1G -type f 2>/dev/null   # the few big ones
ncdu /var                     # interactive, if it is installed
```

**O `-x` é a opção que as pessoas esquecem.** Sem ele, o `du /` entra em todo
sistema de arquivos montado, inclusive montagens de rede, e você espera muito por
uma resposta sobre um disco que não era o da sua pergunta.

E o `du` informa **blocos usados**, não bytes no arquivo — então um arquivo
esparso informa pouco, e mil arquivos de um byte informam quatro megabytes. O
`du --apparent-size` dá o outro número, e a diferença entre eles normalmente é o
fato mais interessante.

## Três conferências, em ordem

| | |
|---|---|
| `df -h` | a área de dados está cheia |
| `df -i` | os inodes estão cheios |
| `lsof +L1` | está sendo segurado aberto por algo, apagado |

**Rode as três antes de apagar qualquer coisa.** A terceira especialmente: apagar
mais arquivos para liberar espaço num sistema de arquivos cujo espaço está preso
num arquivo já apagado não consegue nada, e é muito fácil gastar vinte minutos
provando isso.
