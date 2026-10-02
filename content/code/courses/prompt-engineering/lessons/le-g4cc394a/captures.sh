#!/usr/bin/env bash
# The terminal sessions quoted in lesson 29 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged: five files of model turns under runs/, written with put below and
# shown in the lesson. THE TURNS WERE WRITTEN BY THE COURSE, knowing what the
# tools would return; no model is reachable from the machine. bin/agent plays
# them back, and the parsing, the tools, the allow-list and the step limit are
# real (lab.sh prints the loop in full).
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

put runs/refund.txt <<'T'
# Question: four soups of the day, R$ 27.90 each, paid by card, all served
# cold. How much goes back, how, and does anybody have to approve it?
Thought: The handbook has the rules for refunds. I need the one about approval.
Action: search[refund approval manager]
---
Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
Action: calculator[4 * 27.90]
---
Thought: 111.6 is above 100, so the manager approves it. How does the money go back?
Action: search[refund card cash]
---
Thought: Back to the card they paid with, not in cash.
Answer: R$ 111.60, refunded to the card, once the shift manager has approved it.
T
put runs/ignored.txt <<'T'
Thought: I need the rule about approval first.
Action: search[refund approval manager]
---
Thought: Now the total for four soups.
Action: calculator[4 * 27.90]
---
Thought: That is a normal refund.
Answer: R$ 111.60 back to the card. No approval is needed.
T
put runs/paren.txt <<'T'
Thought: Four soups at R$ 27.90.
Action: calculator(4 * 27.90)
T
put runs/comma.txt <<'T'
Thought: Four soups at R$ 27,90.
Action: calculator[4 * 27,90]
---
Thought: The calculator wants a decimal point.
Action: calculator[4 * 27.90]
---
Answer: R$ 111.60.
T
put runs/email.txt <<'T'
Thought: Above R$ 100 needs the manager. I will ask for approval by e-mail.
Action: send_email[manager@example.com | Please approve a refund of R$ 111.60 for table 4.]
---
Thought: I may not send e-mail in this task. A person has to ask the manager.
Answer: R$ 111.60 to the card. Ask the shift manager to approve it before refunding.
T

block thought-action-observation
on 'cat runs/refund.txt'
on 'agent runs/refund.txt'

block when-it-goes-wrong
on 'agent runs/ignored.txt'
on 'agent runs/paren.txt'
on 'agent runs/comma.txt'
on 'agent runs/refund.txt --max-steps 2'
on 'agent runs/email.txt'
