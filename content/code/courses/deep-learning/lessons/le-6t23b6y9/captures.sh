#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of deep-learning, as a script that
# produces them. THE AUTHOR'S, NOT THE STUDENT'S: the lesson shows every command,
# every program and the whole of corpus.txt, and nothing here names a file the
# student does not have.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Every program comes out of the lesson's own sections through lab/shown.py, so
# what ran is what the page shows. corpus.txt is not a program, so it comes out
# of the lesson the same way by hand: the first unlabelled fence of
# characters-words-subwords.md, byte for byte. Recorded on Ubuntu 24.04,
# Python 3.12.3, tokenizers 0.23.3, torch 2.14.1 on the processor, four
# processors and no graphics card, TZ=America/Sao_Paulo, on 2026-10-10. Nothing
# is downloaded: the tokenizer is trained here, from that file.
. "$(dirname "${LAB_SH:-../../lab.sh}")/lab/capture.sh"
L=le-6t23b6y9
HERE=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
lab reset

python3 - "$HERE/characters-words-subwords.md" > /home/ana/dl/corpus.txt <<'PY' || exit 1
import re, sys
lines, body, inside = open(sys.argv[1]).read().split("\n"), [], False
for line in lines:
    if not inside and line == "```":
        inside = True
    elif inside and line.startswith("```"):
        break
    elif inside:
        body.append(line)
if not body:
    sys.exit("captures: no corpus fence in characters-words-subwords.md")
sys.stdout.write("\n".join(body) + "\n")
PY

use split.py
block split
on 'wc corpus.txt'
on 'python split.py'

use bpe.py
block bpe
on 'python bpe.py'

use tok.py
block tok
on 'python tok.py'

use lookup.py
block lookup
on 'python lookup.py'

use near.py
block near
on 'python near.py'

use bill.py
block bill
on 'python bill.py'
