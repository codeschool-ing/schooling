#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of streaming, as a script that
# produces them. Its output is not committed: run it and compare.
#
#   sudo bash ../../lab.sh install le-94k5phwh installing-a-registry.md
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-94k5phwh.out 2>&1
#
# STAGED, not typed, and said here: the lab starts from a fresh one-node
# cluster with nothing running beside it, so the registry starts empty; the
# topics are made by the script, as the lesson tells the student to. Nothing
# was NOT run. The registry is stopped at the end.
. "$(dirname "$0")/../../lab/capture-lib.sh"

lab reset 1 >/dev/null
API=localhost:8080/apis/ccompat/v7

block json-topic
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-json --partitions 3'
vm 'python tills.py --count 20 --rate 0 --topic sales-json'
vm 'python totals.py'
block renamed
vm 'python till_v2.py'
vm 'python totals.py'

block avro-demo
vm 'python avro_demo.py'

block verify
home 'sha512sum apicurio-registry-app-3.3.3-all.tar.gz | cut -d" " -f1'
home 'cat apicurio-registry-app-3.3.3-all.tar.gz.sha512; echo'
block start
vm 'nohup java -jar ~/apicurio/quarkus-run.jar > ~/apicurio/registry.log 2>&1 &'
vm "until curl -s $API/subjects; do sleep 1; done; echo"
echo "# (author) registry rss kB: $(ps -o rss= -p "$(pgrep -u ubuntu -f '^java -jar .*quarkus-run')")" >&2

block register
vm './register.sh sales-avro-value sale.avsc'
vm "curl -s $API/subjects; echo"
vm "curl -s $API/subjects/sales-avro-value/versions/1; echo"
vm './register.sh sales-avro-value sale.avsc'

block produce
vm 'kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales-avro --partitions 3'
vm 'python avro_tills.py --count 10'
block wire
vm 'kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic sales-avro --partition 0 --offset 0 --max-messages 1 2>/dev/null | od -A d -t x1z'
block read
vm 'python avro_read.py'

block config
vm "curl -s $API/config; echo"
vm "curl -s -X PUT -H 'Content-Type: application/vnd.schemaregistry.v1+json' --data '{\"compatibility\": \"BACKWARD\"}' $API/config/sales-avro-value; echo"
block v2
vm "jq '.fields += [{\"name\": \"till\", \"type\": \"string\", \"default\": \"unknown\"}]' sale.avsc > sale-v2.avsc"
vm 'python avro_tills.py --schema sale-v2.avsc --count 1 2>&1 | tail -1'
vm './register.sh sales-avro-value sale-v2.avsc'
block renamed-refused
vm "jq '.fields[4].name = \"amount\"' sale.avsc > sale-renamed.avsc"
vm './register.sh sales-avro-value sale-renamed.avsc'
vm "curl -s $API/subjects/sales-avro-value/versions; echo"

block mixed
vm 'python avro_tills.py --schema sale-v2.avsc --count 5 --seed 2'
vm 'python avro_read.py'
vm 'python avro_read.py sale-v2.avsc'

run 'kill $(pgrep -f "^java -jar .*quarkus-run")' >/dev/null
