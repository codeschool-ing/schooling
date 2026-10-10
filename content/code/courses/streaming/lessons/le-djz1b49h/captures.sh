#!/usr/bin/env bash
# The terminal sessions quoted in lesson 15 of streaming (RabbitMQ, SQS and
# SNS), as a script that produces them. Its output is not committed.
#
#   sudo bash ../../lab.sh install le-djz1b49h installing-rabbitmq.md   (once)
#   sudo bash captures.sh > /tmp/le-djz1b49h.out 2>&1
#
# STAGED, not typed, and said here:
# - This machine has no systemd, so apt did not start RabbitMQ. It is started
#   here with `rabbitmq-server -detached` and then reset to an empty node
#   (rabbitmqctl stop_app / reset / start_app), so every queue and exchange
#   in the lesson is created by the lesson's programs. On a VM, apt starts it
#   under systemd at install and at every boot; that start was NOT run here.
# - The two packers, Ana and Bia, and moto_server run in terminals of their
#   own; Ana is started one second before Bia. The workers' share of the six
#   orders depends on that timing.
# - moto is an emulator of SQS and SNS. Nothing here talked to AWS.
# - moto_server's request log, in its own terminal, is not quoted.
# - Kafka is not used by this lesson and is not touched.
. "$(dirname "$0")/../../lab/capture-lib.sh"
META=/tmp/le-djz1b49h.meta; : > "$META"

# The programs this lesson tells the student to save, extracted from its own .md
# exactly as `lab.sh files` does (same pattern), so the capture runs the lesson's text
# even while another lesson's draft stops `lab.sh files`.
myfiles() {
  python3 - "$(cd "$(dirname "$0")" && pwd)" <<'PY'
import glob, json, os, re, sys
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
for md in sorted(glob.glob(sys.argv[1] + "/*.md")):
    if md.endswith(".pt.md"): continue
    for name, lang, body in pat.findall(open(md, encoding="utf-8").read()):
        if lang == "schooling-example":
            body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
        open("/home/ubuntu/work/" + name, "w", encoding="utf-8").write(body)
        os.chown("/home/ubuntu/work/" + name, 1000, 1000)
        print(name, file=sys.stderr)
PY
}
myfiles

pkill -u ubuntu -f '^python (rabbit_work|.*moto_server)' || true
pkill -u ubuntu -f 'bin/moto_server' || true
rabbitmqctl -q stop >/dev/null 2>&1 9>&-; sleep 2
rabbitmq-server -detached 9>&- >/dev/null 2>&1
for i in $(seq 1 60); do rabbitmqctl -q status >/dev/null 2>&1 && break; sleep 1; done
{ rabbitmqctl -q stop_app && rabbitmqctl -q reset && rabbitmqctl -q start_app; } >/dev/null 2>&1 9>&-
LQ='sudo rabbitmqctl list_queues name messages_ready messages_unacknowledged consumers'

# installing-rabbitmq
block ping
vm 'sudo rabbitmq-diagnostics ping'

# rabbit-basics
block send
vm 'python rabbit_send.py'
vm "$LQ"
block ana-shown
shown 'python rabbit_work.py ana'
block bia-shown
shown 'python rabbit_work.py bia --crash-after 1'
term2 ana 'python rabbit_work.py ana' 1
term2 bia 'python rabbit_work.py bia --crash-after 1' 9
block bia
wait2 bia
block list
vm "$LQ"
block ana
stop2 ana

# routing
block routes
vm 'python rabbit_routes.py'

# dead-letters
block dead
vm 'python rabbit_dead.py'

echo "RSS MB, rabbitmq (beam): $(ps -eo rss=,cmd= | awk '/beam/{s+=$1} END{print int(s/1024)}')" >> "$META"

# sqs-and-sns
block moto-shown
shown 'moto_server -p 5000'
term2 moto 'moto_server -p 5000' 5
block visibility
vm 'python sqs_demo.py visibility'
block fifo
vm 'python sqs_demo.py fifo'
block fanout
vm 'python sqs_demo.py fanout'
echo "RSS MB, moto: $(ps -u ubuntu -o rss=,cmd= | awk '/moto_server/{s+=$1} END{print int(s/1024)}')" >> "$META"
stop2 moto > /tmp/le-djz1b49h.moto
rabbitmqctl -q stop >/dev/null 2>&1 9>&-
