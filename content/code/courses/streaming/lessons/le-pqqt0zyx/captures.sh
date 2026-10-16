#!/usr/bin/env bash
# The terminal sessions quoted in lesson 1 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh tools && sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-pqqt0zyx.out
#
# STAGED, not typed, and said here: the lab is emptied before the first
# cluster is made, so `new` runs on a machine that never had one; the
# failures in when-setup-fails are each provoked by the line above them
# (a cluster killed with -9 stands in for a restarted virtual machine, a
# Python web server holds port 9092, and a copy of cluster.sh is given
# Windows line endings).
. "$(dirname "$0")/../../lab/capture-lib.sh"

pkill -u ubuntu -f '^[^ ]*java ' || true; sleep 1
run 'rm -rf ~/kafka-data' >/dev/null

block verify
home 'sha512sum kafka_2.13-4.3.1.tgz | cut -d" " -f1'
home 'cut -d: -f2 kafka_2.13-4.3.1.tgz.sha512 | tr -d " \n" | tr A-F a-f; echo'

block first-cluster
vm 'chmod +x cluster.sh'
vm './cluster.sh new 1'
vm './cluster.sh start'
block status
vm './cluster.sh status'
block ls
vm 'ls ~/kafka-data/node1 ~/kafka-data/node1/log'

block topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3'
block consumer-start
shown 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true'
term2 consumer 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --formatter-property print.key=true' 6
block tills
vm 'python tills.py --count 5 --rate 2'
sleep 2
block consumer
stop2 consumer
block again
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales --from-beginning --max-messages 5'

# when-setup-fails
block fail-nocluster
run './cluster.sh stop; mv ~/kafka-data ~/kafka-data.aside' >/dev/null
vm './cluster.sh start'
run 'mv ~/kafka-data.aside ~/kafka-data && ./cluster.sh start' >/dev/null
block fail-new-running
vm './cluster.sh new 1'
block fail-restart
run './cluster.sh kill 1' >/dev/null
vm './cluster.sh status'
vm './cluster.sh start'
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --list'
block fail-port
run './cluster.sh stop' >/dev/null
term2 web 'python -m http.server 9092' 2
vm './cluster.sh start'
vm 'ss -ltnp | grep 9092'
stop2 web >/dev/null
run './cluster.sh start' >/dev/null
block fail-crlf
run 'cp cluster.sh /tmp/cluster.unix && sed -i "s/\$/\r/" cluster.sh' >/dev/null
vm './cluster.sh status'
vm 'file cluster.sh'
vm "sed -i 's/\\r\$//' cluster.sh"
vm 'file cluster.sh'
vm './cluster.sh status'
run 'cmp cluster.sh /tmp/cluster.unix && echo same-as-before' | grep -q same-as-before || echo "!!! cluster.sh did not come back byte for byte"
