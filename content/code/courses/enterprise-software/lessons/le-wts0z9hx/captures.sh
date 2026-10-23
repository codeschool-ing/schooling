#!/usr/bin/env bash
# The terminal sessions quoted in lesson 10 of enterprise-software, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# idempotent-consumer.md and outbox.md (and the same fences in their .pt.md
# files) was copied from running it:
#
#   bash captures.sh
#
# Nothing is installed and nothing comes from outside the lesson. The three
# files the student writes are TAKEN FROM the lesson itself, so they cannot
# drift from what it shows:
#
#   make-messages.sh  the `sh` fence in idempotent-consumer.md whose first line
#                     is "# make-messages.sh"
#   consumer.py       the `schooling-example` in idempotent-consumer.md whose
#                     file is consumer.py, its parts joined with a newline, as
#                     the copy button does
#   outbox.py         the `schooling-example` in outbox.md whose file is
#                     outbox.py, joined the same way
#
# All of it runs in one fresh temporary directory, which the prompt shows as a
# bare "$ ". A line after "$ " is what the student typed; the lines below it
# are what it printed, standard error included.
#
# STAGED, and said so in the lesson: the relay's crash. `outbox.py relay
# --crash` stops the relay after it publishes and before it marks the row
# sent; it is an option of the program the student reads, not a trick of this
# script. The three blocks run in order in the same directory, so the ledger
# that "absorbed" reads already holds the three payments from "consumer".
#
# Recorded 2026-10-23 on Linux with Python 3.13.16, TZ=America/Sao_Paulo.

set -euo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$HERE" "$WORK" <<'PY'
import json, pathlib, re, sys
here, work = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])

def fences(name):
    md = (here / name).read_text()
    return re.findall(r"^```([^\n]*)\n(.*?)^```$", md, flags=re.S | re.M)

def example(name, file):
    found = [json.loads(body) for label, body in fences(name)
             if label == "schooling-example" and json.loads(body).get("file") == file]
    assert len(found) == 1, f"{name} must show {file} once"
    return "\n".join(part["code"] for part in found[0]["parts"]) + "\n"

script = [body for label, body in fences("idempotent-consumer.md")
          if label == "sh" and body.startswith("# make-messages.sh")]
assert len(script) == 1, "the lesson must show make-messages.sh once"
(work / "make-messages.sh").write_text(script[0])
(work / "consumer.py").write_text(example("idempotent-consumer.md", "consumer.py"))
(work / "outbox.py").write_text(example("outbox.md", "outbox.py"))
PY

cd "$WORK"
# what the student typed at a bare prompt, and everything it printed
run() { printf '$ %s\n' "$*"; bash -c "$*" 2>&1 || true; }
block() { printf '##### %s\n' "$1"; }

block consumer
run 'sh make-messages.sh'
run 'python3 consumer.py first.jsonl'
run 'python3 consumer.py again.jsonl'

block outbox
run 'python3 outbox.py pay NF-18240 "Mercado Central" 48000'
run 'python3 outbox.py pay NF-18241 "Casa Minas" 91050'
run 'python3 outbox.py relay --crash'
run 'python3 outbox.py relay'
run 'cat queue.jsonl'

block absorbed
run 'python3 consumer.py queue.jsonl'
