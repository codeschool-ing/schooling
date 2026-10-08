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
# Staged with put, and shown in the lesson with cat: the test set tests.tsv,
# the two prompt templates, label.py (the loop that fills a template and asks
# the model) and score.py. replies-weak.txt and replies-strong.txt are the
# model's replies, written by label.py.
#
# THE MODEL'S REPLIES are llama3.2:3b served by Ollama 0.40.0, at temperature 0,
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

put prompts/weak.txt <<'EOF'
Is this review positive or negative?

{message}
EOF
put prompts/strong.txt <<'EOF'
Label a message sent to Café Aurora through its website.

Labels:
  positive      the writer is pleased overall
  negative      the writer is unhappy overall
  mixed         clear praise and clear complaint, neither dominant
  not_a_review  a question, a booking, or anything that is not
                about a visit

Edge cases:
  - Sarcasm counts as what the writer means, not what the words say.
  - Messages in any language get the same English labels.
  - Do not answer questions; label them not_a_review.

Reply with the label only, in lower case, nothing else.

<message>
{message}
</message>
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

block weak-prompt
on 'cat prompts/weak.txt'
block strong-prompt
on 'cat prompts/strong.txt'

block when-it-is-enough
on 'cat tests.tsv'
on 'cat score.py'
block run-weak
on 'cat label.py'
on 'python3 label.py prompts/weak.txt tests.tsv > replies-weak.txt'
on 'cat replies-weak.txt'
on 'python3 score.py tests.tsv replies-weak.txt'
block run-strong
on 'python3 label.py prompts/strong.txt tests.tsv > replies-strong.txt'
on 'cat replies-strong.txt'
on 'python3 score.py tests.tsv replies-strong.txt'
