#!/usr/bin/env bash
# The terminal sessions quoted in lesson 21 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged with put, and shown in the lesson with cat: three short prompts at
# zero, one and few shots; the labelling prompt without examples, with four
# examples run together with the input, and with them marked off as examples;
# and, again, lesson 20's tests.tsv, label.py and score.py, which the student
# already has. tok counts and prices the prompts at illustrative prices given
# on the command line, not any provider's.
#
# THE MODEL'S REPLIES (every ask, and every reply label.py collects) are
# llama3.2:3b served by Ollama 0.40.0, at temperature 0, captured on
# 7 October 2026.
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

put prompt-zero.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
EOF
put prompt-few.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Reply with the label only, in lower case, nothing else.

<message>Oh lovely, a cold croissant again. Truly the highlight of my week.</message>
negative

<message>Can I book the terrace for six people on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud to talk.</message>
mixed

<message>Melhor café da rua, e o bolo de laranja é perfeito.</message>
positive

<message>
{message}
</message>
EOF

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
put label.py <<'EOF'
import subprocess, sys

template = open(sys.argv[1], encoding="utf-8").read()
for line in open(sys.argv[2], encoding="utf-8"):
    tid, want, text = line.rstrip("\n").split("\t")
    prompt = template.replace("{message}", text)
    reply = subprocess.run(["ask", prompt, "--temperature", "0", "--plain"],
                           capture_output=True, text=True).stdout
    print(" ".join(reply.split()))
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
put prompts/shot-zero.txt <<'EOF'
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Great, another forty minutes for a coffee.</message>
EOF
put prompts/shot-one.txt <<'EOF'
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Great, another forty minutes for a coffee.</message>
EOF
put prompts/shot-few.txt <<'EOF'
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Oh lovely, a cold croissant again.</message>
negative

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud.</message>
mixed

<message>Best coffee on the street.</message>
positive

<message>Great, another forty minutes for a coffee.</message>
EOF
put prompt-few2.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

These four messages are already labelled, as examples:

  Oh lovely, a cold croissant again. Truly the highlight of my week. -> negative
  Can I book the terrace for six people on Saturday? -> not_a_review
  Friendly staff, but the music was far too loud to talk. -> mixed
  Melhor café da rua, e o bolo de laranja é perfeito. -> positive

Label only the message between the tags below. Reply with the label
only, in lower case, nothing else.

<message>
{message}
</message>
EOF

block examples-as-specification
on 'toylm generate "the bread" --temperature 0'
on 'toylm generate "question : is the bread fresh ? answer :" --temperature 0'
on 'toylm generate "question : when does the café open ? answer :" --temperature 0'
on 'toylm next "question : when does the café open ? answer :"'
block shots
on 'cat prompts/shot-zero.txt'
on 'ask - --temperature 0 < prompts/shot-zero.txt'
block shot-one
on 'cat prompts/shot-one.txt'
on 'ask - --temperature 0 < prompts/shot-one.txt'
block shot-few
on 'cat prompts/shot-few.txt'
on 'ask - --temperature 0 < prompts/shot-few.txt'

block choosing-examples
on 'cat prompt-few.txt'
block score-few
on 'cat prompt-zero.txt'
on 'python3 label.py prompt-zero.txt tests.tsv > replies-zero.txt; python3 score.py tests.tsv replies-zero.txt'
on 'python3 label.py prompt-few.txt tests.tsv > replies-few.txt; python3 score.py tests.tsv replies-few.txt'
block few2
on 'cat prompt-few2.txt'
on 'python3 label.py prompt-few2.txt tests.tsv > replies-few2.txt; python3 score.py tests.tsv replies-few2.txt'
block cost
on 'tok count prompt-zero.txt prompt-few.txt prompt-few2.txt'
on 'tok cost prompt-zero.txt -o 2 -i 2.50 -p 10'
on 'tok cost prompt-few.txt -o 2 -i 2.50 -p 10'
