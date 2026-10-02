#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is staged: no model was called. The replies are files ana wrote with
# put, standing for what a model might send back, and each one is shown in the
# lesson with cat before anything reads it: three JSON replies (one valid, one
# with a sentence in front, one written in Python's syntax), two replies with a
# tagged label (one with the tag, one without), and two CSV replies (one with
# unquoted commas inside fields, one quoted). What reads them is real:
# Python's json.tool, re and csv modules.
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

put replies/good.json <<'EOF'
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
EOF
put replies/chatty.json <<'EOF'
Sure! Here is the JSON for review 3:
{
  "review": 3,
  "sentiment": "negative",
  "topics": ["wait", "tea"],
  "staff_praised": true
}
EOF
put replies/python.json <<'EOF'
{
  'review': 3,
  'sentiment': 'negative',
  'topics': ['wait', 'tea'],
  'staff_praised': True,
}
EOF
put replies/tagged.txt <<'EOF'
The review complains about a fifteen-minute wait and praises the staff.
<label>negative</label>
EOF
put replies/untagged.txt <<'EOF'
The review complains about a fifteen-minute wait and praises the staff.
Label: negative
EOF
put replies/menu.csv <<'EOF'
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,18,50,tomato
cinnamon bun,9.00,contains nuts, eggs and milk
EOF
put replies/menu-quoted.csv <<'EOF'
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,"18,50",tomato
cinnamon bun,9.00,"contains nuts, eggs and milk"
EOF

block json
on 'cat replies/good.json'
on 'python3 -m json.tool replies/good.json > /dev/null; echo "exit $?"'
on 'cat replies/chatty.json'
on 'python3 -m json.tool replies/chatty.json > /dev/null; echo "exit $?"'
on 'cat replies/python.json'
on 'python3 -m json.tool replies/python.json > /dev/null; echo "exit $?"'

block tags-and-markdown
on 'cat replies/tagged.txt'
on "python3 -c \"import re, sys; m = re.search(r'<label>(.*?)</label>', open(sys.argv[1]).read()); print(m.group(1) if m else 'no label found'); sys.exit(0 if m else 1)\" replies/tagged.txt; echo \"exit \$?\""
on 'cat replies/untagged.txt'
on "python3 -c \"import re, sys; m = re.search(r'<label>(.*?)</label>', open(sys.argv[1]).read()); print(m.group(1) if m else 'no label found'); sys.exit(0 if m else 1)\" replies/untagged.txt; echo \"exit \$?\""

block csv
on 'cat replies/menu.csv'
on 'python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu.csv'
on 'cat replies/menu-quoted.csv'
on 'python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu-quoted.csv'
