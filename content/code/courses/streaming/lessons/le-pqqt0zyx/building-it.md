---
title: A cluster in one script
version: 1
---

Kafka arrives as a set of programs and no opinion about how to run them. A node needs a
configuration file, a directory it owns, a one-time **format** of that directory and a command that
starts it; three nodes need all of that three times, with ports that do not collide and a list
of who votes in the cluster's elections. Typing it by hand is how a lab ends up in a state nobody
can explain, so the course does it with one script, which you save now and use in every lesson
after this one.

Save this as `~/work/cluster.sh`:

```schooling-example
{
  "file": "cluster.sh",
  "language": "sh",
  "parts": [
    {
      "code": "#!/usr/bin/env bash\n# cluster.sh: a Kafka cluster of one or three nodes, all on this machine.\n#\n#   cluster.sh new 1      a fresh cluster of one node (deletes the old one)\n#   cluster.sh new 3      a fresh cluster of three nodes\n#   cluster.sh start      start every node, and wait until each one answers\n#   cluster.sh stop       stop every node, cleanly\n#   cluster.sh status     which nodes are running\n#   cluster.sh kill N     stop node N without warning, as a crash would\n#   cluster.sh start N    start node N on its own\n#\n# Node N takes client connections on port 9091+N and talks to the other\n# nodes' controllers on 9191+N. Everything it stores is under ~/kafka-data/nodeN.\nset -euo pipefail\n\nKAFKA=$HOME/kafka\nDATA=$HOME/kafka-data\n",
      "note": "The usage, which is also what the script prints when it is called with nothing. **Node N listens on 9091+N**, so a one-node cluster is the familiar `localhost:9092`."
    },
    {
      "code": "nodes() { ls -d \"$DATA\"/node* 2>/dev/null | sed 's/.*node//' | sort -n; }\npid_of() { pgrep -f \"^[^ ]*java .*kafka-data/node$1/server.properties\" || true; }\nanswers() { (exec 3<>\"/dev/tcp/localhost/$1\") 2>/dev/null; }\n",
      "note": "Three small helpers. A node is found by the configuration file on its command line, and **\"answers\" means something accepts a connection on its port**, which is the only test that a server is ready rather than merely started."
    },
    {
      "code": "new() {\n  local n=$1 voters=\"\" i id\n  case $n in 1|3) ;; *) echo \"new: 1 or 3 nodes, not $n\" >&2; exit 2 ;; esac\n  if [ -n \"$(pgrep -f \"^[^ ]*java .*kafka-data/node\" || true)\" ]; then\n    echo \"new: the cluster is running; cluster.sh stop first\" >&2; exit 1\n  fi\n  for i in $(seq 1 \"$n\"); do voters+=\"${voters:+,}$i@localhost:$((9191 + i))\"; done\n  rm -rf \"$DATA\"\n  id=$(\"$KAFKA\"/bin/kafka-storage.sh random-uuid)",
      "note": "`new` refuses to run under a live cluster, then deletes the old data. `controller.quorum.voters` lists the nodes that vote on the cluster's state, and every node must be given the same list."
    },
    {
      "code": "  for i in $(seq 1 \"$n\"); do\n    mkdir -p \"$DATA/node$i\"\n    cat > \"$DATA/node$i/server.properties\" <<CONF\nprocess.roles=broker,controller\nnode.id=$i\ncontroller.quorum.voters=$voters\nlisteners=PLAINTEXT://localhost:$((9091 + i)),CONTROLLER://localhost:$((9191 + i))\nadvertised.listeners=PLAINTEXT://localhost:$((9091 + i))\ncontroller.listener.names=CONTROLLER\ninter.broker.listener.name=PLAINTEXT\nlistener.security.protocol.map=CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT\nlog.dirs=$DATA/node$i/log\nnum.partitions=1\ndefault.replication.factor=$n\noffsets.topic.replication.factor=$n\ntransaction.state.log.replication.factor=$n\ntransaction.state.log.min.isr=1\nshare.coordinator.state.topic.replication.factor=$n\nshare.coordinator.state.topic.min.isr=1\ngroup.initial.rebalance.delay.ms=0\nCONF",
      "note": "One configuration file per node. **Each node is both a broker, which stores data, and a controller, which keeps the cluster's metadata**; lesson 5 separates the two jobs. The replication factors follow the size of the cluster, so the topics Kafka creates for itself survive a lost node when there are three."
    },
    {
      "code": "    \"$KAFKA\"/bin/kafka-storage.sh format -t \"$id\" -c \"$DATA/node$i/server.properties\" >/dev/null\n  done\n  echo \"new: $n node(s), cluster id $id\"\n}\n",
      "note": "**Formatting writes the cluster's id into the node's directory.** A node refuses to start on a directory that was never formatted, and refuses to join a cluster whose id differs from its own."
    },
    {
      "code": "start_one() {\n  local i=$1\n  [ -f \"$DATA/node$i/server.properties\" ] || { echo \"node $i: does not exist\" >&2; exit 1; }\n  if [ -n \"$(pid_of \"$i\")\" ]; then echo \"node $i: already running\"; return; fi\n  if answers $((9091 + i)); then\n    echo \"node $i: port $((9091 + i)) is taken by another program\" >&2; exit 1\n  fi\n  LOG_DIR=\"$DATA/node$i/logs\" KAFKA_HEAP_OPTS=\"-Xms512m -Xmx512m\" \\\n    \"$KAFKA\"/bin/kafka-server-start.sh -daemon \"$DATA/node$i/server.properties\"\n}\n",
      "note": "A node that is already running is left alone, and **a port somebody else holds is refused before Java starts**, because the node would otherwise fail ten seconds later with the reason buried in its log. Each node gets 512 MB of heap, which is plenty for a lab and a fraction of what a production broker is given. Its own log files go to `~/kafka-data/nodeN/logs`."
    },
    {
      "code": "wait_for() {\n  local i=$1 t\n  for t in $(seq 1 60); do\n    if answers $((9091 + i)); then echo \"node $i: up on localhost:$((9091 + i))\"; return; fi\n    if [ -z \"$(pid_of \"$i\")\" ]; then\n      echo \"node $i: stopped while starting; the reason is in $DATA/node$i/logs/server.log\" >&2\n      exit 1\n    fi\n    sleep 1\n  done\n  echo \"node $i: not answering after 60 seconds\" >&2; exit 1\n}\n",
      "note": "Starting is not the same as being ready. The script waits for the port, and **if the process dies first it says where the reason is** instead of waiting a minute for nothing."
    },
    {
      "code": "case ${1:-} in\n  new)    new \"${2:-}\" ;;\n  start)\n    if [ -n \"${2:-}\" ]; then start_one \"$2\"; wait_for \"$2\"; exit; fi\n    [ -n \"$(nodes)\" ] || { echo \"start: no cluster; cluster.sh new 1 first\" >&2; exit 1; }\n    for i in $(nodes); do start_one \"$i\"; done\n    for i in $(nodes); do wait_for \"$i\"; done ;;\n  stop)\n    for i in $(nodes); do\n      p=$(pid_of \"$i\"); [ -n \"$p\" ] || continue\n      kill \"$p\"\n      while kill -0 \"$p\" 2>/dev/null; do sleep 1; done\n      echo \"node $i: stopped\"\n    done ;;\n  kill)\n    p=$(pid_of \"${2:?kill which node?}\")\n    [ -n \"$p\" ] || { echo \"node $2: not running\" >&2; exit 1; }\n    kill -9 \"$p\"; echo \"node $2: killed\" ;;\n  status)\n    [ -n \"$(nodes)\" ] || { echo \"no cluster; cluster.sh new 1 makes one\"; exit; }\n    for i in $(nodes); do\n      if [ -z \"$(pid_of \"$i\")\" ]; then echo \"node $i: stopped\"\n      elif answers $((9091 + i)); then echo \"node $i: up on localhost:$((9091 + i))\"\n      else echo \"node $i: starting\"; fi\n    done ;;\n  *) sed -n '2,13p' \"$0\" | sed 's/^# \\{0,1\\}//'; exit 2 ;;\nesac",
      "note": "The commands. `stop` sends the polite signal and waits for each node to finish writing; `kill` sends `-9`, which is what a power cut looks like to the node, and lesson 5 uses it on purpose."
    }
  ]
}
```

The surest way to get the file into the virtual machine intact is to open an editor there, `nano
~/work/cluster.sh`, paste, and save with Ctrl+O and Ctrl+X. Then make it executable, make a cluster
of one node and start it:

```
ubuntu@stream:~/work$ chmod +x cluster.sh
ubuntu@stream:~/work$ ./cluster.sh new 1
new: 1 node(s), cluster id 7UGCBjViRiyLoDGZdMaXyA
ubuntu@stream:~/work$ ./cluster.sh start
node 1: up on localhost:9092
```

The first command prints nothing, which is how Linux says it worked. `new` takes a few seconds,
because each `kafka-storage.sh` starts a Java virtual machine; `start` takes a few more, because
the node replays its own metadata before it opens the port.

**The cluster id is new every time you run `new`**, so yours is a different string. Everything
else should match. Run `status` whenever you are not sure what is running:

```
ubuntu@stream:~/work$ ./cluster.sh status
node 1: up on localhost:9092
```

## What is on disk now

`new` wrote one directory per node, and the node has been writing into it since it started:

```
ubuntu@stream:~/work$ ls ~/kafka-data/node1 ~/kafka-data/node1/log
/home/ubuntu/kafka-data/node1:
log
logs
server.properties

/home/ubuntu/kafka-data/node1/log:
__cluster_metadata-0
bootstrap.checkpoint
cleaner-offset-checkpoint
log-start-offset-checkpoint
meta.properties
recovery-point-offset-checkpoint
replication-offset-checkpoint
```

`server.properties` is the configuration the script generated, `logs` holds what the node says
about itself, and `log` is where the data goes. The two names differ by one letter and mean
different things, an old Kafka habit: **`log` is the data, because Kafka stores a topic as a log**,
which is lesson 2's subject. `__cluster_metadata-0` is the controller's own log, where every topic
you create and every node that joins is written down. `meta.properties` holds the cluster id.

One thing to know before you stop for the day: **the cluster does not start on its own** when the
virtual machine does. After a restart, `./cluster.sh start` brings it back, with everything it had
stored.
