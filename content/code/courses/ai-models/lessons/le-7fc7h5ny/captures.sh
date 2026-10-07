#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   sudo bash ../../lab.sh up        # once: Ollama, the models, ~/desk
#   sudo bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. train_sorter.py, tokens.mjs, sort.mjs and sort.html are the
# student's, shown whole in the lesson and taken from it here. Transformers.js
# is installed from npm into ~/desk, as the lesson has the student do.
#
# THE BROWSER. The student opens the page in their own browser and reads the
# Network tab. The lesson quotes the same visit as a headless Chromium recorded
# it, with lab/browse.mjs (the author's, never the student's), which prints a
# header naming the browser and the page; nothing the student types runs it.
#
# huggingface.co could not be reached from this machine, so the model is not one
# from the Hub: train_sorter.py trains a tiny one on the first thirty of ana's
# cases and writes it out in the layout a Hub repository for Transformers.js
# has. Everything after that is real: Transformers.js and ONNX Runtime at the
# versions npm installed, in Node and in Chromium, and every number they print.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture-lib.sh
browse() {
  ( cd $AUTHOR/node && PLAYWRIGHT_BROWSERS_PATH=${PLAYWRIGHT_BROWSERS_PATH:-/opt/pw-browsers} node browse.mjs "$@" 2>&1 )
}

lab reset >/dev/null

block runtime
on 'node --version'
on 'npm init -y > /dev/null && npm install @huggingface/transformers@4.3.0'
on 'grep -h "\"version\"" node_modules/@huggingface/transformers/package.json node_modules/onnxruntime-node/package.json node_modules/onnxruntime-web/package.json'
on 'grep -A3 "^var DEFAULT_DEVICE_DTYPE_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs'
on 'grep -A13 "^var DEFAULT_DTYPE_SUFFIX_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs'

block files
give train_sorter.py files.md python 1
on 'pip install -q numpy==2.4.6 onnx==1.23.1'
on 'python train_sorter.py'
on 'find models -type f | sort | xargs wc -c'
on 'cat models/lantern-sorter/config.json'
on 'python -c "import onnx; g = onnx.load(\"models/lantern-sorter/onnx/model.onnx\").graph; print(*[n.op_type for n in g.node]); print([i.name for i in g.input], \"->\", [o.name for o in g.output])"'
give tokens.mjs files.md js 1
on 'node tokens.mjs "Where is my order LB-20488? It has not arrived."'

block node
give sort.mjs node.md example sort.mjs
on 'time node sort.mjs'

block browser
give sort.html browser.md html 1
printf 'ana@desk:~/desk$ python -m http.server 8600 --bind 127.0.0.1\n'
lab exec ana "PYTHONUNBUFFERED=1 setsid python -m http.server 8600 --bind 127.0.0.1 > http.out 2>&1 < /dev/null & echo \$! > http.pid" < /dev/null
sleep 1
lab exec ana 'head -1 http.out' < /dev/null
browse http://127.0.0.1:8600/sort.html
on 'sed "s/, { dtype: \"fp32\" }//" sort.html > sort-q8.html && grep -c dtype sort-q8.html'
browse http://127.0.0.1:8600/sort-q8.html --wait 15
lab exec ana 'kill $(cat http.pid); rm -f http.pid http.out' < /dev/null
