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
# Staged with put: five turn files in runs/, WRITTEN BY THE COURSE and played
# back by agent so that each rule of the loop shows on its own, which the lesson
# says; and two versions of the ReAct prompt, react-v1.txt and react.txt, shown
# with cat and diff.
#
# THE MODEL'S TURNS in live-react and live-words are llama3.2:3b served by
# Ollama 0.40.0, at temperature 0, captured on 7 October 2026.
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

put prompts/react-v1.txt <<'P'
Answer the question. You can use these tools:
  search[words]        the best matching line of the café's staff handbook
  calculator[sum]      arithmetic with numbers and + - * /
Use this format, and write one Action at a time:
Thought: what you know and what you need next
Action: one tool call
Observation: (the tool's reply is written here for you)
... repeat as needed, then:
Answer: the final answer
P
put prompts/react.txt <<'P'
Answer the question. You can use these tools:
  search[refund approval]   the best matching line of the café's staff handbook
  calculator[3 * 2.50]      arithmetic with numbers and + - * /
Use this format. Write one Thought and one Action, then stop and wait:
Thought: what you know and what you need next
Action: search[...] or calculator[...]
The program then writes an Observation line with the tool's reply. When you
have every fact you need, write:
Thought: why you have the answer
Answer: the final answer
P

block live-react
on 'cat prompts/react.txt'
on 'agent --live "Four soups of the day, R\$ 27.90 each, paid by card, all served cold. How much goes back, how, and does anybody have to approve it?" --prompt prompts/react.txt --max-steps 6'
block thought-action-observation
on 'cat runs/refund.txt'
on 'agent runs/refund.txt'

block when-it-goes-wrong
on 'agent runs/ignored.txt'
on 'agent runs/paren.txt'
block live-words
on 'diff prompts/react-v1.txt prompts/react.txt'
on 'agent --live "Four soups of the day, R\$ 27.90 each, paid by card, all served cold. How much goes back, how, and does anybody have to approve it?" --prompt prompts/react-v1.txt --max-steps 6'
block when-2
on 'agent runs/comma.txt'
on 'agent runs/refund.txt --max-steps 2'
on 'agent runs/email.txt'
