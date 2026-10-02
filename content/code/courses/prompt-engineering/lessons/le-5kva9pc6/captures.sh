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
# What is staged: no model was called. Everything the commands read is a file
# ana wrote with put, and each one is shown in the lesson with cat: a JSON
# Schema for triaging complaints to Café Aurora, four triage replies standing
# for what a model might send back (one valid, two that break the schema, one
# that obeys it and breaks a rule of the café), two raw replies for repair (one
# wrapped in a code fence and sentences, one with a category the schema does
# not allow), one complaint, and rules.py, a check of the café's own rules.
# What reads them is real: validate and repair from lab.sh (jsonschema 4.26.0),
# and Python.
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

block validating-meaning
on 'cat complaints/7.txt'
on 'cat triage/7.json'
on 'validate schema.json triage/7.json; echo "exit $?"'
on 'grep 100 handbook/refunds.md'
on 'cat rules.py'
on 'python3 rules.py triage/7.json; echo "exit $?"'
on 'python3 rules.py triage/good.json; echo "exit $?"'
