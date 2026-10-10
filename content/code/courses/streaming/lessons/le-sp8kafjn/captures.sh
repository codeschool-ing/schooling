#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of streaming (watermarks and late
# data), as a script that produces them. Its output is not committed: run it
# and compare.
#
#   sudo bash ../../lab.sh files
#   sudo bash captures.sh > /tmp/le-sp8kafjn.out
#
# STAGED, not typed, and said here: watermark.py is extracted from
# watermark-in-action.md byte for byte by the function below, and so is
# lesson 9's late_tills.py from its skew.md, so the files that run are the
# files the lessons show. The lab starts from a fresh one-node cluster
# (`lab.sh reset 1`), which is why choosing-the-bound makes the `late` topic
# again, as the lesson tells a student whose cluster was rebuilt.
# Nothing was left unrun.
. "$(dirname "$0")/../../lab/capture-lib.sh"
D=$(cd "$(dirname "$0")" && pwd)

extract() {
python3 - "$1" <<'PY'
import json, os, pwd, re, sys
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
for name, lang, body in pat.findall(open(sys.argv[1], encoding="utf-8").read()):
    if lang == "schooling-example":
        body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
    path = "/home/ubuntu/work/" + name
    open(path, "w", encoding="utf-8").write(body)
    u = pwd.getpwnam("ubuntu"); os.chown(path, u.pw_uid, u.pw_gid)
PY
}
extract "$D/watermark-in-action.md"
extract "$D/../le-jzre5f62/skew.md"

lab reset 1 >/dev/null 2>&1
K='--bootstrap-server localhost:9092'

block run
vm 'python watermark.py'
block lateness
vm 'python watermark.py --lateness 5'
block late-topic
vm "kafka-topics.sh $K --create --topic sales-late --partitions 1"
vm 'python watermark.py --late-topic sales-late'
block late-read
vm "kafka-console-consumer.sh $K --topic sales-late --from-beginning --max-messages 2"
block bound6
vm 'python watermark.py --bound 6'
block late-again
vm "kafka-topics.sh $K --create --topic late --partitions 1 --config retention.ms=-1"
vm 'python late_tills.py'
block percentiles
vm "kafka-console-consumer.sh $K --topic late --from-beginning --max-messages 360 2>/dev/null \\
  | jq -r '.at[:19] + \"Z\" | fromdate' \\
  | awk '\$1 > seen { seen = \$1 } { print seen - \$1 }' | sort -n \\
  | awk '{ d[NR] = \$1 } \$1 <= 0 { w0++ } \$1 <= 60 { w60++ } \$1 <= 120 { w120++ }
         END { split(\"50 80 85 90 95 99 100\", p, \" \")
               for (i = 1; i <= 7; i++) { k = int(NR * p[i] / 100 + 0.99); print \"p\" p[i], d[k], \"s\" }
               print \"within 0 s:\", w0, \" within 60 s:\", w60, \" within 120 s:\", w120 }'"
block partitions2
vm 'python watermark.py --partitions 2'
block partitions3
vm 'python watermark.py --partitions 3'
block idle
vm 'python watermark.py --partitions 3 --idle 3'
