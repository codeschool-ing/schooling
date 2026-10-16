---
title: Losing a datanode, and the copies coming back
version: 1
---

**Kill the second datanode**, the way lesson 2 killed a worker. The script kept its process id in a
file, which saves finding it:

```
ana@lab:~/big$ kill -9 $(cat ~/hdfs/dn2/hadoop-ana-datanode.pid)
```

Nothing happens at first, and that is the design. A datanode that misses a heartbeat may only be
slow, and copying its blocks elsewhere costs the whole cluster disk and network, so the namenode
waits. With the settings in `hdfs.sh` it waits about a minute; with Hadoop's defaults it waits ten
and a half. Then it declares the datanode dead, counts the blocks that have lost a copy, and asks the
survivors to make new ones.

Ask the namenode every ten seconds how many datanodes it counts as dead, and how many of the file's
blocks are short of three copies. `fsck` also prints a line saying where it is connecting, every
time:

```
ana@lab:~/big$ for i in $(seq 15); do sleep 10; echo "$(date +%T) $(hdfs dfsadmin -report -dead | grep -c '^Name') dead, $(hdfs fsck /raw/clicks-2025.csv | grep 'Under-replicated')"; done
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:29 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:43 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:43:57 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:11 0 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:26 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:40 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:44:55 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:09 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:23 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:38 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:45:52 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:07 1 dead,  Under-replicated blocks:	7 (70.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:21 1 dead,  Under-replicated blocks:	2 (20.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:36 1 dead,  Under-replicated blocks:	0 (0.0 %)
Connecting to namenode via http://localhost:9870/fsck?ugi=ana&path=%2Fraw%2Fclicks-2025.csv
21:46:50 1 dead,  Under-replicated blocks:	0 (0.0 %)
```

**The namenode declared the datanode dead about seventy seconds after the kill, and found seven of
the ten blocks short of a copy.** About two minutes later every one had three copies again, made by
the surviving datanodes copying among themselves. Nobody did anything, and at no moment was any block missing: the file could be read
throughout. That is the point of three copies. The arithmetic of lesson 2 says some disk is always
failing; three copies turn that from lost data into background traffic.

Two things the counts do not show:

- **The repair costs the cluster.** Every block copied is 128 MB read and written again because of
  one lost machine. A real datanode holds terabytes, and its loss starts hours of
  copying that competes with the jobs for the same disks and network. HDFS limits how fast it
  re-replicates for that reason.
- **Two copies lost at once is survivable; three is not.** A block whose three copies were on three
  machines that failed together is gone, and `fsck` reports the file as corrupt. Racks exist in the
  placement rule for exactly this: the commonest way to lose three machines at once is to lose the
  rack they share.

Start the datanode again and the namenode now sees four copies of some blocks, and deletes the
spares in the background:

```sh
HADOOP_CONF_DIR=~/hdfs/dn2/conf HADOOP_PID_DIR=~/hdfs/dn2 HADOOP_LOG_DIR=~/hdfs/dn2/logs \
  hdfs --daemon start datanode
```

or simply `sh hdfs.sh stop` and `sh hdfs.sh start`.
