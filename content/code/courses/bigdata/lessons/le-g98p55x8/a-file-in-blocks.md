---
title: One file, ten blocks, thirty copies
version: 1
---

**Put the whole year of clicks into HDFS as one file**, so that it is large enough to be cut into
blocks. `hdfs dfs` is the shell for HDFS, with the commands you know from Linux behind a dash:
`-ls`, `-mkdir`, `-mv`, `-rm`. `-put -` reads from standard input, so the 365 compressed files can
be unpacked and joined on the way in, with their header lines dropped:

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

Under a minute for 1.2 GB, written three times. The `3` in the listing is the replication.

`hdfs fsck` asks the namenode what it knows about a file. Its full output names every block with
identifiers too long to read, so `sed` trims them to the block, its length and the datanodes that
hold it:

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

**Ten blocks: nine of exactly 134,217,728 bytes, which is 128 MB, and a last one of what was left.**
Each lists three datanodes, by the data ports the script gave them, and no block has two copies on
the same one. The namenode spreads the copies so that every datanode holds some of the file and none
holds all of it: with four datanodes and thirty copies, each holds seven or eight.

A block is an ordinary file on a datanode's disk. The first block, found in the data directories:

```
ana@lab:~/big$ find ~/hdfs -name 'blk_1073741825*' | xargs ls -l
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn1/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn1/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn3/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn3/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
-rw-r--r-- 1 ana ana 134217728 Oct 15 21:40 /home/ana/hdfs/dn4/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825
-rw-r--r-- 1 ana ana   1048583 Oct 15 21:40 /home/ana/hdfs/dn4/data/current/BP-2064471904-127.0.1.1-1792111181569/current/finalized/subdir0/subdir0/blk_1073741825_1001.meta
```

**Three files of exactly 128 MB, under three different datanodes**, each with a small `.meta` file
beside it holding the block's checksums. A datanode checks those on every read, so a block damaged
on disk is noticed and read from another copy instead of being handed to a program.

On a real cluster those three directories would be on three machines, and usually on two different
racks: HDFS puts the second and third copies on a rack other than the first's, if it has been told
which machine is in which rack, so that a rack losing power does not take all three. This lab has
one rack.
