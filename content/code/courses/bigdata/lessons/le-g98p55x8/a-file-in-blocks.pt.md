---
title: Um arquivo, dez blocos, trinta cópias
version: 1
---

**Ponha o ano inteiro de cliques no HDFS como um arquivo só**, para que ele seja grande o bastante
para ser cortado em blocos. O `hdfs dfs` é o shell do HDFS, com os comandos que você conhece do
Linux atrás de um hífen: `-ls`, `-mkdir`, `-mv`, `-rm`. O `-put -` lê da entrada padrão, então os
365 arquivos compactados podem ser descompactados e juntados no caminho, sem as linhas de cabeçalho:

```
ana@lab:~/big$ hdfs dfs -mkdir -p /raw
ana@lab:~/big$ time (zcat data/raw/clicks/*/*.gz | grep -v '^event_id' | hdfs dfs -put - /raw/clicks-2025.csv)

real	0m52.141s
user	0m20.976s
sys	0m7.996s
ana@lab:~/big$ hdfs dfs -ls -h /raw
Found 1 items
-rw-r--r--   3 ana supergroup      1.2 G 2026-10-15 21:41 /raw/clicks-2025.csv
```

Menos de um minuto para 1,2 GB, escritos três vezes. A coluna `3` na listagem é a replicação.

O `hdfs fsck` pergunta ao namenode o que ele sabe de um arquivo. A saída completa nomeia cada bloco
com identificadores longos demais para ler, então o `sed` os reduz ao bloco, ao tamanho e aos
datanodes que o guardam:

```
ana@lab:~/big$ hdfs fsck /raw/clicks-2025.csv -files -blocks -locations | grep -E '^[0-9]+\.' | sed -E 's/BP-[^:]*://; s/DatanodeInfoWithStorage\[//g; s/,DS-[^]]*\]//g'
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&files=1&blocks=1&locations=1&path=%2Fraw%2Fclicks-2025.csv
0. blk_1073741825_1001 len=134217728 Live_repl=3  [127.0.0.1:9466, 127.0.0.1:9166, 127.0.0.1:9366]
1. blk_1073741826_1002 len=134217728 Live_repl=3  [127.0.0.1:9366, 127.0.0.1:9166, 127.0.0.1:9266]
2. blk_1073741827_1003 len=134217728 Live_repl=3  [127.0.0.1:9466, 127.0.0.1:9366, 127.0.0.1:9266]
3. blk_1073741828_1004 len=134217728 Live_repl=3  [127.0.0.1:9266, 127.0.0.1:9466, 127.0.0.1:9166]
4. blk_1073741829_1005 len=134217728 Live_repl=3  [127.0.0.1:9366, 127.0.0.1:9266, 127.0.0.1:9466]
5. blk_1073741830_1006 len=134217728 Live_repl=3  [127.0.0.1:9366, 127.0.0.1:9166, 127.0.0.1:9466]
6. blk_1073741831_1007 len=134217728 Live_repl=3  [127.0.0.1:9466, 127.0.0.1:9366, 127.0.0.1:9166]
7. blk_1073741832_1008 len=134217728 Live_repl=3  [127.0.0.1:9266, 127.0.0.1:9366, 127.0.0.1:9466]
8. blk_1073741833_1009 len=134217728 Live_repl=3  [127.0.0.1:9166, 127.0.0.1:9266, 127.0.0.1:9466]
9. blk_1073741834_1010 len=83279770 Live_repl=3  [127.0.0.1:9466, 127.0.0.1:9266, 127.0.0.1:9366]
```

**Dez blocos: nove de exatamente 134.217.728 bytes, que são 128 MB, e um último com o que sobrou.**
Cada um lista três datanodes, pelas portas de dados que o script deu, e nenhum bloco tem duas
cópias no mesmo. O namenode espalha as cópias para que todo datanode guarde parte do arquivo e
nenhum guarde tudo: com quatro datanodes e trinta cópias, cada um guarda sete ou oito.

Um bloco é um arquivo comum no disco de um datanode. O primeiro bloco, achado nos diretórios de
dados:

```
ana@lab:~/big$ find ~/hdfs -name 'blk_1073741825*' | xargs ls -l
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn1/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn1/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn3/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn3/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn4/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn4/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
```

**Três arquivos de exatamente 128 MB, sob três datanodes diferentes**, cada um com um pequeno
arquivo `.meta` ao lado guardando os checksums do bloco. Um datanode os confere em toda leitura,
então um bloco danificado no disco é percebido e lido de outra cópia em vez de entregue a um
programa.

Num cluster de verdade esses três diretórios estariam em três máquinas, e em geral em dois racks
diferentes: o HDFS põe a segunda e a terceira cópias num rack diferente do da primeira, se alguém
disse a ele que máquina está em que rack, para que um rack sem energia não leve as três. Este
laboratório tem um rack só.
