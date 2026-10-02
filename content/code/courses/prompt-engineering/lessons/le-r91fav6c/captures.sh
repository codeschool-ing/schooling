#!/usr/bin/env bash
# The terminal sessions quoted in lesson 20 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# What is staged: no model was called. tests.tsv is a test set the course
# wrote: eight short messages to Café Aurora, each with the label a person gave
# it. replies-weak.txt and replies-strong.txt are what a model might send back,
# one reply per line, for the weak prompt and the strong prompt shown in the
# lesson as illustrations; the course wrote them as stand-ins. score.py is
# real, and so is the comparison it makes. Every file is shown with cat.
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

put tests.tsv <<'EOF'
r1	positive	Lovely cinnamon bun and the oat flat white was perfect. Will come back on Sunday.
r2	mixed	Waited fifteen minutes for a tea at noon. The staff were kind about it.
r3	negative	The soup was cold and nobody came to take it back.
r4	positive	Best bread in the neighbourhood, still warm at eight.
r5	negative	Great, another forty minutes for a coffee. Wonderful service.
r6	not_a_review	Do you open on public holidays?
r7	mixed	The cake was dry but the coffee made up for it.
r8	positive	O pão de queijo estava ótimo e o café também.
EOF
put replies-weak.txt <<'EOF'
Positive!
Mixed: the wait was long, but the staff were kind.
negative
positive
positive
On public holidays the café follows the Sunday hours.
mixed
Positivo
EOF
put replies-strong.txt <<'EOF'
positive
mixed
negative
positive
positive
not_a_review
mixed
positive
EOF
put score.py <<'EOF'
import sys

tests = [line.rstrip("\n").split("\t") for line in open(sys.argv[1], encoding="utf-8")]
replies = [line.rstrip("\n") for line in open(sys.argv[2], encoding="utf-8")]
right = 0
for (tid, want, text), got in zip(tests, replies):
    if got == want:
        right += 1
    else:
        print("%s  wanted %-13s got %s" % (tid, want, got))
print("%d of %d right" % (right, len(tests)))
EOF

block when-it-is-enough
on 'cat tests.tsv'
on 'cat score.py'
on 'cat replies-weak.txt'
on 'python3 score.py tests.tsv replies-weak.txt'
on 'cat replies-strong.txt'
on 'python3 score.py tests.tsv replies-strong.txt'
