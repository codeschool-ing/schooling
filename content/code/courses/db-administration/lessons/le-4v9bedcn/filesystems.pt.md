---
title: O sistema de arquivos, e as opções de montagem que não se mexem
version: 1
---

É tentador achar que um banco de dados quer algo exótico embaixo dele: dispositivos crus, um
sistema de arquivos especial, um guia inteiro de opções de montagem. O PostgreSQL quer o contrário.
**Ele guarda os dados em arquivos comuns e se apoia no sistema operacional para o cache e para
escrevê-los no disco**, e é por isso que a lição 6 dimensionou o cache dele contra o do kernel.
Então o sistema de arquivos deve ser o mais comum e mais testado que a sua distribuição oferece.

No Linux isso quer dizer um de dois:

| sistema de arquivos | onde você o encontra |
|---|---|
| **ext4** | o padrão no Ubuntu e no Debian, e o que o servidor do curso usa |
| **XFS** | o padrão no Red Hat Enterprise Linux e nos seus parentes |

Os dois são maduros, os dois são onde o PostgreSQL é mais testado, e a diferença de velocidade entre
eles para um banco é pequena perto da diferença entre discos. **Escolha o que a sua distribuição
instala por padrão** e gaste a atenção no disco. ZFS e btrfs também funcionam, e trazem snapshots e
checksums próprios junto com uma história de ajuste própria; são uma escolha que alguém faz de
propósito, nunca uma em que se cai sem querer. Um sistema de arquivos de rede como o NFS é o que se
deve evitar para um diretório de dados, a não ser que o fornecedor do armazenamento o documente para
bancos, porque uma escrita que o servidor considera feita pode ainda estar a caminho de outro lugar.

## Lendo as opções do sistema de arquivos que você tem

O `findmnt --target` diz em que sistema de arquivos um caminho está, o tipo dele e as opções com que
foi montado:

```
ana@db:~$ findmnt --target /var/lib/postgresql/16/main --output TARGET,FSTYPE,OPTIONS
TARGET FSTYPE OPTIONS
/      ext4   rw,relatime,discard,no_prefetch_block_bitmaps,resv_strict,resuid=65534,resgid=65534
```

Esta é a máquina de gravação, então a maior parte dessas opções pertence ao computador em que ela
rodou, e as suas serão mais curtas: algo como `rw,relatime`. O diretório de dados está no sistema de
arquivos raiz, o que é normal num servidor pequeno e serve para este curso. Um servidor que importa
ganha **um sistema de arquivos só para os dados**, para que os logs do sistema operacional e os
downloads de alguém não encham o disco embaixo do banco, e para que o banco não encha o disco
embaixo do sistema operacional.

## Quais opções importam

**`relatime`**, o padrão, atualiza o horário de acesso de um arquivo no máximo uma vez por dia. O
`noatime` acaba com isso de vez, o que economiza uma pequena escrita depois de leituras e não custa
nada que o PostgreSQL use. É a única opção que vale a pena acrescentar.

**As barreiras de escrita são as que nunca se removem.** Uma barreira é o sistema de arquivos
mandando o disco pôr em armazenamento estável o que já aceitou antes de aceitar mais, e é o que faz
um `fsync` significar alguma coisa. O ext4 ainda aceita `barrier=0`, e guias antigos ainda o
recomendam por velocidade. Com ele, uma queda de energia pode perder transações que o PostgreSQL já
informou como confirmadas, e pode corromper os arquivos de jeitos que nenhuma recuperação conserta.
O XFS removeu a sua versão dessa opção exatamente por esse motivo.

Um sistema de arquivos feito para os dados, montado no boot, é uma linha no `/etc/fstab`. Descubra o
identificador do sistema de arquivos com `sudo blkid`, e use-o em vez de um nome de dispositivo,
que pode mudar de um boot para outro:

```conf
UUID=<the uuid blkid printed>  /var/lib/postgresql  ext4  defaults,noatime  0  2
```

Monte-o antes de instalar o PostgreSQL, ou pare o cluster e mova o diretório para ele primeiro.
**Um diretório de dados cujo sistema de arquivos não montou é um diretório vazio**, e um servidor
iniciado nele é um servidor sem dados.
