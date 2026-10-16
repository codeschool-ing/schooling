---
title: HDFS on your machine, with four datanodes
version: 1
---

**HDFS comes with Hadoop, and Hadoop is installed the way Spark was**: a release from the Apache
Software Foundation, checked, unpacked and linked. In the machine's shell, from your home directory:

```sh
curl -O https://downloads.apache.org/hadoop/common/hadoop-3.5.0/hadoop-3.5.0.tar.gz
curl -O https://downloads.apache.org/hadoop/common/hadoop-3.5.0/hadoop-3.5.0.tar.gz.sha512
sha512sum -c hadoop-3.5.0.tar.gz.sha512
tar -xzf hadoop-3.5.0.tar.gz
ln -s hadoop-3.5.0 hadoop
cat >> ~/.sparkrc <<'END'
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
export HADOOP_HOME=~/hadoop
export PATH=$HADOOP_HOME/bin:$PATH
END
. ~/.sparkrc
cd ~/big
```

The release is 581 MB. Hadoop's scripts need `JAVA_HOME` set, where Spark's found Java on the path
by themselves. Only Hadoop's `bin` goes on the path and not its `sbin`, because both projects have a
`start-all.sh` there and the second one on the path would quietly win.

```
ana@lab:~$ sha512sum -c hadoop-3.5.0.tar.gz.sha512
hadoop-3.5.0.tar.gz: OK
ana@lab:~$ hadoop version | head -n 1
Hadoop 3.5.0
```

## One namenode and four datanodes

A real HDFS has one datanode per machine. Here the four share one machine, so each needs its own
directory, its own ports and its own copy of the configuration. One script writes all of it and
starts and stops the five processes. Save it as `~/big/hdfs.sh`:

```schooling-example
{
  "language": "sh",
  "file": "hdfs.sh",
  "parts": [
    {
      "code": "#!/bin/sh\n# One namenode and four datanodes on this machine, each datanode with its\n# own directory, its own ports and its own copy of the configuration.\n#   sh hdfs.sh setup    write the configuration and format the namenode (once)\n#   sh hdfs.sh start    start the five processes\n#   sh hdfs.sh stop     stop them\nset -e\nH=$HOME/hdfs\nCONF=$HADOOP_HOME/etc/hadoop\n\n"
    },
    {
      "code": "shared() {\n  cat <<END\n  <property><name>dfs.replication</name><value>3</value></property>\n  <property><name>dfs.namenode.name.dir</name><value>file://$H/name</value></property>\n  <property><name>dfs.heartbeat.interval</name><value>3</value></property>\n  <property><name>dfs.namenode.heartbeat.recheck-interval</name><value>15000</value></property>\nEND\n}\n\n",
      "note": "The settings every process shares. `dfs.replication` keeps three copies of every block. The two heartbeat settings make the namenode declare a silent datanode dead after about a minute instead of the default ten and a half, so that section 06 does not take a quarter of an hour."
    },
    {
      "code": "datanode_conf() {\n  n=$1\n  mkdir -p $H/dn$n/conf\n  cp -r $CONF/* $H/dn$n/conf/\n  {\n    echo '<configuration>'\n    shared\n    echo \"  <property><name>dfs.datanode.data.dir</name><value>file://$H/dn$n/data</value></property>\"\n    echo \"  <property><name>dfs.datanode.address</name><value>127.0.0.1:9${n}66</value></property>\"\n    echo \"  <property><name>dfs.datanode.http.address</name><value>127.0.0.1:9${n}64</value></property>\"\n    echo \"  <property><name>dfs.datanode.ipc.address</name><value>127.0.0.1:9${n}67</value></property>\"\n    echo \"  <property><name>dfs.datanode.hostname</name><value>127.0.0.1</value></property>\"\n    echo '</configuration>'\n  } > $H/dn$n/conf/hdfs-site.xml\n}\n\n",
      "note": "Datanode `n` gets its own data directory and three ports with `n` in them: 9166, 9164 and 9167 for the first, 9466, 9464 and 9467 for the fourth. Two processes cannot listen on the same port, which is the only reason one machine needs this. The last line makes each datanode call itself `127.0.0.1`, the name Spark's executors use; section 08 says what happens without it."
    },
    {
      "code": "datanode() {\n  HADOOP_CONF_DIR=$H/dn$2/conf HADOOP_PID_DIR=$H/dn$2 HADOOP_LOG_DIR=$H/dn$2/logs \\\n    hdfs --daemon $1 datanode\n}\n\n",
      "note": "Each datanode is started with its own configuration directory, and with its own place for the file that holds its process id and for its logs."
    },
    {
      "code": "case \"$1\" in\n  setup)\n    cat > $CONF/core-site.xml <<END\n<configuration>\n  <property><name>fs.defaultFS</name><value>hdfs://localhost:9000</value></property>\n</configuration>\nEND\n    { echo '<configuration>'; shared; echo '</configuration>'; } > $CONF/hdfs-site.xml\n    for n in 1 2 3 4; do datanode_conf $n; done\n    hdfs namenode -format -nonInteractive 2>&1 | grep -o 'Storage directory .* has been successfully formatted.' ;;\n  start)\n    hdfs --daemon start namenode\n    for n in 1 2 3 4; do datanode start $n; done ;;\n  stop)\n    for n in 1 2 3 4; do datanode stop $n; done\n    hdfs --daemon stop namenode ;;\nesac\n",
      "note": "`setup` writes `core-site.xml`, which tells every client where the namenode listens, and the namenode's own `hdfs-site.xml`, then formats the namenode: an empty filesystem with no files in it yet."
    }
  ]
}
```

Four datanodes, and not three, so that the cluster can lose one and still have three places to keep
three copies; section 06 needs that. Each datanode takes about 200 MB of memory, and the namenode
about 300.

```
ana@lab:~/big$ sh hdfs.sh setup
Storage directory /home/ana/hdfs/name has been successfully formatted.
```

The namenode is formatted once. Formatting again gives an empty filesystem with a new identity,
which datanodes that remember the old one will refuse to join; the list at the end of this section
says how to recover. Now start the five processes and ask the namenode who joined:

```
ana@lab:~/big$ sh hdfs.sh start
WARNING: /home/ana/hdfs/dn1/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn2/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn3/logs does not exist. Creating.
WARNING: /home/ana/hdfs/dn4/logs does not exist. Creating.
ana@lab:~/big$ hdfs dfsadmin -report | grep -E '^(Live|Name)'
Live datanodes (4):
Name: 127.0.0.1:9166 (localhost)
Name: 127.0.0.1:9266 (localhost)
Name: 127.0.0.1:9366 (localhost)
Name: 127.0.0.1:9466 (localhost)
```

**Four live datanodes**, each named by the address and the data port the script gave it. The first
start creates the log directories, and says so.

The namenode has a page of its own at port 9870, reachable the way lesson 1 reached Spark's. The
commands in this lesson ask it the same questions from the shell.

### When it does not start

- **`Incompatible clusterIDs` in a datanode's log**, in `~/hdfs/dn1/logs`: the namenode was
  formatted again after the datanodes first joined. `sh hdfs.sh stop`, `rm -rf ~/hdfs`, then
  `setup` and `start` again. The data in HDFS is lost, and in this course all of it can be put
  back from `~/big/data`.
- **`JAVA_HOME is not set and could not be found`**: `~/.sparkrc` was not read in this terminal.
- **`Live datanodes (0)`** right after `start`: they take a few seconds to register. Ask again.
- **`Call From lab/127.0.1.1 to localhost:9000 failed on connection exception`**: the namenode is
  not running. Its log is in `~/hadoop/logs`.
