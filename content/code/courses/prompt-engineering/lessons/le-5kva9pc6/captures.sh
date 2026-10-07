#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Everything the commands read is a file ana wrote with put, and each one is
# shown in the lesson with cat: a JSON Schema for triaging complaints to Café
# Aurora; four triage replies and two raw replies WRITTEN BY THE COURSE, each to
# show one thing validate or repair says, and the lesson says so; two
# complaints; the triage prompt; triage.py, the retry loop; and rules.py, a
# check of the café's own rules. repair is read out of repair.md.
#
# THE MODEL'S REPLIES, inside triage.py's runs in the blocks retry and
# validating-meaning, are llama3.2:3b served by Ollama 0.40.0, at temperature 0,
# captured on 7 October 2026.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.
set -uo pipefail
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
# on 'command': what ana typed in ~/pe, and what it printed.
on() { printf 'ana@lab:~/pe$ %s\n' "$*"; lab exec "$*" 2>&1 || true; }
# put PATH: a file ana wrote in ~/pe, from stdin. Its content is shown in the lesson.
put() { lab exec "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }
# One capture at a time: every run rebuilds ~/pe from nothing.
exec 9>/var/tmp/pe-capture.lock; flock 9
lab reset >/dev/null

put schema.json <<'EOF'
{
  "type": "object",
  "properties": {
    "category": {"enum": ["wrong_item", "cold_or_late", "allergen", "billing", "other"]},
    "refund": {"type": "boolean"},
    "refund_amount": {"type": "number", "minimum": 0},
    "summary": {"type": "string", "maxLength": 80}
  },
  "required": ["category", "refund", "summary"],
  "additionalProperties": false
}
EOF
put triage/good.json <<'EOF'
{"category": "cold_or_late", "refund": false, "summary": "Waited fifteen minutes for a tea at noon; staff were kind."}
EOF
put triage/bad-1.json <<'EOF'
{"category": "slow service", "refund": "no", "summary": "The customer waited fifteen minutes for a tea at noon, which is too long, although the staff were kind about it."}
EOF
put triage/bad-2.json <<'EOF'
{"category": "cold_or_late", "refund": false, "mood": "annoyed"}
EOF
put replies/fenced.txt <<'EOF'
Here is the triage for the complaint:

```json
{"category": "wrong_item", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
```

Let me know if you need anything else!
EOF
put replies/wrong-enum.txt <<'EOF'
{"category": "drinks", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
EOF
put complaints/7.txt <<'EOF'
I was charged twice for my lunch today: R$ 140 on my card instead of R$ 70. Please give me back what I paid twice.
EOF
put triage/7.json <<'EOF'
{"category": "billing", "refund": true, "refund_amount": 140, "summary": "Charged twice for lunch; wants the double charge back."}
EOF
put rules.py <<'EOF'
import json, sys

t = json.load(open(sys.argv[1]))
problems = []
if t["refund"] and "refund_amount" not in t:
    problems.append("refund is true but no refund_amount was given")
if not t["refund"] and t.get("refund_amount", 0) > 0:
    problems.append("refund is false but refund_amount is above zero")
if t.get("refund_amount", 0) > 100:
    problems.append("refund_amount %s is above R$ 100: the shift manager must approve" % t["refund_amount"])
print("\n".join(problems) or "no rule broken")
sys.exit(1 if problems else 0)
EOF

put complaints/3.txt <<'EOF'
I ordered an oat flat white and got cow's milk. I'm lactose intolerant and paid R$ 14 for it.
EOF
put prompts/triage.txt <<'EOF'
Triage one complaint to Café Aurora. Reply with one JSON object that
matches this JSON Schema, and nothing else:

{
  "type": "object",
  "properties": {
    "category": {"enum": ["wrong_item", "cold_or_late", "allergen", "billing", "other"]},
    "refund": {"type": "boolean"},
    "refund_amount": {"type": "number", "minimum": 0},
    "summary": {"type": "string", "maxLength": 80}
  },
  "required": ["category", "refund", "summary"],
  "additionalProperties": false
}

refund is true when the café owes the customer money back, and
refund_amount is how much, in reais.
EOF
put triage.py <<'EOF'
"""triage.py COMPLAINT: sort one complaint with the model, checked by repair.

The complaint goes to the model with prompts/triage.txt in front of it. Each
reply goes through repair; when it fails, repair's follow-up message is sent
back as the next turn. After MAX_ATTEMPTS replies the failure is recorded for
a person, and nothing is invented to fill the gap.
"""
import json
import subprocess
import sys

MAX_ATTEMPTS = 3

prompt = open("prompts/triage.txt", encoding="utf-8").read()
complaint = open(sys.argv[1], encoding="utf-8").read()
messages = [{"role": "user", "content": prompt + "\nComplaint:\n" + complaint}]

for attempt in range(1, MAX_ATTEMPTS + 1):
    json.dump(messages, open("triage-chat.json", "w", encoding="utf-8"))
    reply = subprocess.run(["ask", "--chat", "triage-chat.json", "--plain", "--temperature", "0"],
                           capture_output=True, text=True).stdout
    open("triage-reply.txt", "w", encoding="utf-8").write(reply)
    check = subprocess.run(["repair", "schema.json", "triage-reply.txt"],
                           capture_output=True, text=True)
    print("attempt %d" % attempt)
    print("  " + check.stdout.strip().replace("\n", "\n  "))
    if check.returncode == 0:
        sys.exit(0)
    follow_up = check.stdout.partition("would be:\n\n")[2] or "Reply with only the JSON object."
    messages += [{"role": "assistant", "content": reply}, {"role": "user", "content": follow_up}]

print("failed after %d attempts: recorded for a person, with the last reply" % MAX_ATTEMPTS)
sys.exit(1)
EOF

block a-schema
on 'cat schema.json'
on 'cat triage/good.json'
on 'validate schema.json triage/good.json; echo "exit $?"'
on 'cat triage/bad-1.json'
on 'validate schema.json triage/bad-1.json; echo "exit $?"'
on 'cat triage/bad-2.json'
on 'validate schema.json triage/bad-2.json; echo "exit $?"'

block repair
on 'cat -n replies/fenced.txt'
on 'repair schema.json replies/fenced.txt; echo "exit $?"'
on 'cat replies/wrong-enum.txt'
on 'repair schema.json replies/wrong-enum.txt; echo "exit $?"'
block retry
on 'cat prompts/triage.txt'
on 'cat triage.py'
on 'cat complaints/3.txt'
on 'python3 triage.py complaints/3.txt'

block validating-meaning
on 'cat complaints/7.txt'
on 'python3 triage.py complaints/7.txt'
block course-7
on 'cat triage/7.json'
on 'validate schema.json triage/7.json; echo "exit $?"'
block rules
on 'grep 100 handbook/refunds.md'
on 'cat rules.py'
on 'python3 rules.py triage/7.json; echo "exit $?"'
on 'python3 rules.py triage/good.json; echo "exit $?"'
