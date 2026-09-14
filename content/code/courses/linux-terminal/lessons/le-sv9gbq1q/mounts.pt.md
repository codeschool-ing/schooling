---
title: Montagem: um disco chega como diretório
version: 1
---

A seção 10 da aula 1 já disse: não existem letras de unidade, existe uma árvore, e todo disco da
máquina aparece em algum lugar dentro dela. O verbo para *aparece em algum lugar dentro dela* é
**montar**, e esta seção é o que isso realmente parece.

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Leia as duas pontas juntas. `/dev/vda` é um **dispositivo** — uma entrada em `/dev`, um disco. `/`
é o **ponto de montagem** — um diretório na árvore. Montar é o ato de conectar os dois, e a partir
daquele momento, abrir aquele diretório abre aquele disco.

## Ver o que está montado

Três comandos, cada vez mais específicos:

```
ana@vm:~$ df -h /
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

`df` — *disk free* — é o que você vai digitar. Ele aceita um caminho e responde sobre o sistema de
arquivos em que aquele caminho vive, que é a pergunta útil. Sem argumento, lista tudo.

```
ana@vm:~$ findmnt -no SOURCE,FSTYPE /
/dev/vda ext4
```

`findmnt` é o preciso: o que está montado onde, com que tipo e que opções. `-n` tira o cabeçalho,
`-o` escolhe as colunas.

```
root@vm:/root# lsblk -o NAME,SIZE,TYPE,MOUNTPOINTS /dev/vda /dev/loop0
NAME   SIZE TYPE MOUNTPOINTS
loop0   64M loop /mnt/backups
vda    256G disk /
```

`lsblk` lista **dispositivos de bloco** — o lado do hardware — estejam eles montados ou não. É
essa última parte que faz dele a ferramenta certa quando um disco está *faltando*: o `df` não tem
como mostrar um disco que não está montado, e o `lsblk` tem. Sem argumentos ele lista todos os
dispositivos da máquina; aqui recebeu dois.

Esta máquina é virtual, e é por isso que o disco dela é `vda`. Num laptop você veria `sda` ou
`nvme0n1` com duas ou três linhas `part` embaixo — as partições — e os pontos de montagem ao lado.

**Nomes de dispositivo não são promessas.** `vda` numa máquina virtual, `sda` em algo com SATA,
`nvme0n1p2` num laptop moderno, e as letras são atribuídas na ordem em que o kernel encontrou os
discos. É por isso que o `/etc/fstab` prefere um UUID, logo abaixo.

## O que montar realmente faz com um diretório

A ideia inteira numa sessão só. Um diretório, com algo dentro:

```
root@vm:/root# echo 'this is on the main disk' > /mnt/backups/oops.txt
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/vda        252G   11G   27G  28% /
```

Nada está montado ali ainda, então `/mnt/backups` é um diretório comum no disco principal. Agora
monte algo em cima dele:

```
root@vm:/root# mount -o loop /root/img/disk.img /mnt/backups
root@vm:/root# ls -la /mnt/backups
total 24
drwxr-xr-x 3 root root  4096 Sep 14 22:22 .
drwxr-xr-x 7 root root  4096 Sep 14 22:22 ..
drwx------ 2 root root 16384 Sep 14 22:22 lost+found
root@vm:/root# df -h /mnt/backups
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   24K   52M   1% /mnt/backups
```

**O `oops.txt` sumiu.** Não foi apagado — foi *coberto*. O diretório agora mostra o conteúdo do
sistema de arquivos montado, e o mesmo caminho responde por outro disco. O `df` prova: 56 MB onde
há um instante havia 252 GB.

Trabalhe nele normalmente:

```
root@vm:/root# mkdir /mnt/backups/nightly
root@vm:/root# touch /mnt/backups/nightly/2026-09-14.tar.gz
root@vm:/root# ls -R /mnt/backups
/mnt/backups:
lost+found  nightly

/mnt/backups/nightly:
2026-09-14.tar.gz
```

E desmonte:

```
root@vm:/root# umount /mnt/backups
root@vm:/root# ls -la /mnt/backups
total 12
drwxr-xr-x 2 root root 4096 Sep 14 22:22 .
drwxr-xr-x 7 root root 4096 Sep 14 22:22 ..
-rw-r--r-- 1 root root   25 Sep 14 22:22 oops.txt
root@vm:/root# cat /mnt/backups/oops.txt
this is on the main disk
```

O `oops.txt` voltou, intacto, e o `nightly/` não — ele está no outro disco, esperando ser montado
de novo.

**Três coisas para levar dali**, e a terceira é a que custa dinheiro.

O comando é `umount`, **não** `unmount`. Todo mundo digita errado uma vez.

Um ponto de montagem não precisa estar vazio, e montar não te avisa que ele não estava.

E a cara: **uma rotina de backup escrevendo em `/mnt/backups` sem nada montado ali escreve
alegremente no disco principal.** Sem erro. Até parece que funcionou — existem arquivos, no lugar
certo, com os nomes certos. Isso é descoberto meses depois, normalmente no dia em que alguém
precisa do backup. A aula 11 volta a isso; a defesa é conferir `findmnt /mnt/backups` antes de
escrever, e deixar o diretório desmontado sem permissão de escrita, para a rotina falhar alto em
vez de falhar calada.

## `mount` e `umount` exigem root, e aceitam duas formas

```
sudo mount /dev/sdb1 /mnt/data          # este dispositivo, neste diretório
sudo umount /mnt/data                   # ou: umount /dev/sdb1
```

`-o` passa opções — `ro` para somente leitura, `loop` para montar um *arquivo* como se fosse um
disco, que é como a demonstração acima funcionou e como se monta uma imagem ISO.

O erro que você vai encontrar de verdade é este:

```
root@vm:/mnt/backups# umount /mnt/backups
umount: /mnt/backups: target is busy.
root@vm:/mnt/backups# cd /
root@vm:/# umount /mnt/backups
root@vm:/# echo $?
0
```

Alguma coisa tem um arquivo aberto ali, ou o shell de alguém está sentado dentro — e olhe o prompt
nessa transcrição, porque **o alguém era eu**. Um shell cujo diretório de trabalho está num sistema
de arquivos está usando aquele sistema de arquivos. Saia com `cd` e a desmontagem funciona.

Quando não é você, `lsof +D /mnt/data` ou `fuser -vm /mnt/data` nomeiam o culpado, e a aula 6 é
onde esses dois ficam familiares.

## `/etc/fstab` é a lista do que montar no boot

```
root@vm:/root# cat /etc/fstab
# UNCONFIGURED FSTAB FOR BASE SYSTEM
```

Vazio, nesta máquina, porque ela é uma máquina virtual cujo sistema de arquivos raiz foi montado
pelo que a iniciou, e não a partir de uma tabela. Numa instalação normal ele tem uma linha por
sistema de arquivos, com seis campos cada:

| campo | é | exemplo |
|---|---|---|
| 1 | o que montar | `UUID=2f1a-…` |
| 2 | onde | `/home` |
| 3 | tipo | `ext4` |
| 4 | opções | `defaults,noatime` |
| 5 | dump | `0` — uma flag de backup obsoleta, sempre `0` |
| 6 | ordem do fsck | `1` para a raiz, `2` para os outros, `0` para pular |

**O campo 1 é normalmente um UUID em vez de `/dev/sdb1`**, e esse é o detalhe importante: letras de
dispositivo mudam quando você acrescenta um disco, e um UUID pertence ao próprio sistema de
arquivos. O `blkid` imprime:

```
root@vm:/root# blkid /dev/loop0
/dev/loop0: LABEL="backups" UUID="c26bf719-319e-4ab2-9b16-e641c60ab92e" BLOCK_SIZE="4096" TYPE="ext4"
```

Esse UUID foi gravado no sistema de arquivos quando ele foi criado e viaja com ele — para outra
baia, outra máquina, outra ordem de cabos. Uma máquina que não sobe depois de alguém acrescentar um
segundo disco é quase sempre uma máquina cujo `fstab` nomeava uma letra.

**Editar o `/etc/fstab` errado pode impedir a máquina de dar boot**, então o ritual é: edite, depois
rode `sudo mount -a` — que monta tudo do arquivo que ainda não está montado — e confirme que saiu
em silêncio *antes* de reiniciar. O `mount -a` é o ensaio gratuito.

## Onde você vai encontrar montagens sem configurar nenhuma

| | |
|---|---|
| um pendrive | aparece em `/media/ana/RÓTULO`, montado para você pela área de trabalho |
| uma imagem ISO | `mount -o loop imagem.iso /mnt/iso` |
| um compartilhamento de rede | NFS ou SMB, montado no diretório que você escolher |
| o Windows, dentro do WSL | `/mnt/c` — o mesmo mecanismo, e a razão de ser mais lento |
| um contêiner | o sistema de arquivos dele é todo montagem, e o `-v` do `docker run` acrescenta uma |
| `/proc`, `/sys`, `/dev` | montados, e em disco nenhum — seção 49 |
