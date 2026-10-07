#!/usr/bin/env bash
# The terminal sessions quoted in lesson 8 of prompt-engineering, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh tools     # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# Staged beyond the workbench lab.sh builds: two short Python files ana writes,
# size.py and quant.py, both shown in full in the lesson (size-and-memory). The
# four numbers in quant.py were made up to stand in for weights; no real
# model's weights are involved.
#
# show reads the model lesson 1 pulled: llama3.2:3b, Ollama 0.40.0.
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

block what-a-weight-is
on 'toylm info'
on 'toylm save model.json'
on 'ls -l model.json'
on 'head -c 240 model.json; echo'
on "python3 -c \"import json; print(json.load(open('model.json'))['trigram']['coffee is'])\""

block size-and-memory
put size.py <<'PY'
import sys

weights = float(sys.argv[1])
for bits in (32, 16, 8, 4):
    print("%2d bits: %6.1f GB" % (bits, weights * bits / 8 / 1e9))
PY
on 'python3 size.py 7e9'
on 'python3 size.py 70e9'
put quant.py <<'PY'
w = [0.0173, -0.4121, 0.2958, -0.0846]
print("original:", " ".join("%+.4f" % x for x in w))
for bits in (8, 4):
    levels = 2 ** (bits - 1) - 1
    step = max(abs(x) for x in w) / levels
    back = [round(x / step) * step for x in w]
    err = max(abs(a - b) for a, b in zip(w, back))
    print("%d bits:  " % bits, " ".join("%+.4f" % x for x in back), " largest error %.4f" % err)
PY
on 'python3 quant.py'
block show
on 'ollama show llama3.2:3b | head -7'
block size-3b
on 'python3 size.py 3.2e9'
