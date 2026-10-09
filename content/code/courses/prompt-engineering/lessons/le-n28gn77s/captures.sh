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
# Staged with put: direct.txt and step1.txt, the handbook's opening hours and a
# question, shown in the lesson. rules.txt is the model's reply to step1.txt,
# and step2.txt is built from it by the command the lesson shows.
#
# THE MODEL'S REPLIES (every ask below) are llama3.2:3b served by Ollama 0.40.0,
# at temperature 0, captured on 7 October 2026.
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

block direct
on 'cat direct.txt'
on 'ask - --temperature 0 < direct.txt'
block step1
on 'tail -1 step1.txt'
on 'ask - --temperature 0 --plain < step1.txt > rules.txt; cat rules.txt'
block step2
on '{ sed -n "1,/^<\/handbook>/p" direct.txt; echo; echo "<rules>"; cat rules.txt; echo "</rules>"; echo; echo "Using the rules above, answer the question. $(tail -1 direct.txt)"; } > step2.txt'
on 'ask - --temperature 0 < step2.txt'
block gas
on 'ask "What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0'
on 'ask "Which physical law relates the pressure, temperature and volume of a gas? State it as a formula, in one line." --temperature 0 --plain > law.txt; cat law.txt'
on 'ask "$(cat law.txt)

Using that law: What happens to the pressure of a gas if its temperature is doubled and its volume made eight times larger? Answer in two sentences." --temperature 0'
on 'python3 -c "print(2 / 8)"'

block when-it-helps
on 'tok count direct.txt step1.txt step2.txt'
