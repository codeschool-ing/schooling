#!/usr/bin/env bash
# The terminal sessions quoted in lesson 25 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged: three prompts ana wrote, direct.txt, step1.txt and step2.txt, all
# shown in full in the section "step-back". The <rules> block inside
# step2.txt is the course's illustration of a reply to step1.txt, and the
# lesson says so; no model wrote it. tok is the real tokenizer in lab.sh.
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

HOURS='<handbook>
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
</handbook>
'
QUESTION='Today is Wednesday, and it is a public holiday. At 11:45 a customer asks for a hot toastie. Can the kitchen take the order? Answer yes or no, then one sentence saying why.'
{ printf '%s\n' "$HOURS" "$QUESTION"; } | put direct.txt
{ printf '%s\n' "$HOURS" 'Do not answer any particular question yet. Step back: what general rules decide the last time the kitchen takes a hot food order on a given day? List the rules from the handbook that apply, and what they give for each kind of day.'; } | put step1.txt
{ printf '%s\n' "$HOURS" '<rules>
1. The closing time depends on the day: 18:00 from Monday to Saturday, 12:00 on Sunday.
2. A public holiday follows the Sunday hours, whatever day of the week it falls on.
3. The kitchen stops taking hot food orders 30 minutes before closing.
So the last hot food order is at 17:30 on an ordinary day from Monday to Saturday, and at 11:30 on a Sunday or a public holiday.
</rules>
' "Using the rules above, answer the question. $QUESTION"; } | put step2.txt

block step-back
on 'python3 -c "print(2 / 8)"'

block when-it-helps
on 'tok count direct.txt step1.txt step2.txt'
