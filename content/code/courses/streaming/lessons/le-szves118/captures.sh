#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of streaming (windows), as a
# script that produces them. Its output is not committed: run it and compare.
#
#   sudo bash captures.sh > /tmp/le-szves118.out
#
# Nothing here touches Kafka: windows.py runs over ten sales written into it.
# STAGED, not typed, and said here: windows.py is extracted from tumbling.md
# by the function below, byte for byte, rather than pasted, so the file that
# runs is the file the lesson shows. Nothing was left unrun.
. "$(dirname "$0")/../../lab/capture-lib.sh"

python3 - "$(dirname "$0")/tumbling.md" <<'PY'
import json, os, pwd, re, sys
pat = re.compile(r"^[^\n]*`~/work/([\w.-]+)`[^\n]*:\n\n```([\w-]*)\n(.*?)^```$", re.S | re.M)
for name, lang, body in pat.findall(open(sys.argv[1], encoding="utf-8").read()):
    if lang == "schooling-example":
        body = "\n".join(p["code"] for p in json.loads(body)["parts"]) + "\n"
    path = "/home/ubuntu/work/" + name
    open(path, "w", encoding="utf-8").write(body)
    u = pwd.getpwnam("ubuntu"); os.chown(path, u.pw_uid, u.pw_gid)
PY

block tumbling
vm 'python windows.py tumbling 5'
block hopping
vm 'python windows.py hopping 10 5'
block sliding
vm 'python windows.py sliding 5'
block session
vm 'python windows.py session 5'
block session3
vm 'python windows.py session 3'
block keyed-tumbling
vm 'python windows.py tumbling 5 --by-shop'
block keyed-session
vm 'python windows.py session 5 --by-shop'
block updates
vm 'python windows.py tumbling 5 --updates'
