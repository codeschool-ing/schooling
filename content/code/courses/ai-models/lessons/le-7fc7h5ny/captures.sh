#!/usr/bin/env bash
# The terminal sessions quoted in lesson 13 of ai-models, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED.
#
#   bash ../../lab.sh up        # once: the machine, the SDKs, the documents
#   bash captures.sh
#
# A line that starts with ana@desk:~/desk$ is what ana typed and what it
# printed. STAGED rather than typed: the lab itself (lab.sh reset), the
# programs put below, which the lesson shows in full, and `browse`, a headless
# Chromium that opens ana's page and presses its button in place of her
# (lab/browse.mjs).
#
# huggingface.co could not be reached from the machine this was recorded on,
# so the model is not one from the Hub: `train-sorter` (lab/train_sorter.py)
# trains a tiny one on the first thirty of ana's cases and writes it out in
# the layout a Hub repository for Transformers.js has. Everything after that
# is real: Transformers.js and ONNX Runtime at the versions lab.sh pins, in
# Node and in Chromium, and every number they print.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
cd "$(dirname "$0")"
LAB_SH=${LAB_SH:-../../lab.sh}
lab() { bash "$LAB_SH" "$@"; }
on() { printf 'ana@desk:~/desk$ %s\n' "$*"; lab exec ana "$*" 2>&1 || true; }
put() { lab exec ana "mkdir -p \"\$(dirname '$1')\" && cat > '$1'"; }
block() { printf '##### %s\n' "$1"; }

lab reset >/dev/null

block versions
on 'grep -h "\"version\"" node_modules/@huggingface/transformers/package.json node_modules/onnxruntime-node/package.json node_modules/onnxruntime-web/package.json'

block dtypes
on 'grep -A3 "^var DEFAULT_DEVICE_DTYPE_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs'
on 'grep -A13 "^var DEFAULT_DTYPE_SUFFIX_MAPPING = " node_modules/@huggingface/transformers/dist/transformers.node.mjs'

block files
on 'train-sorter'
on 'find models -type f | sort | xargs wc -c'
on 'cat models/lantern-sorter/config.json'
on 'python -c "import onnx; g = onnx.load(\"models/lantern-sorter/onnx/model.onnx\").graph; print(*[n.op_type for n in g.node]); print([i.name for i in g.input], \"->\", [o.name for o in g.output])"'

put tokens.mjs <<'JS'
import { AutoTokenizer, env } from "@huggingface/transformers";
env.allowRemoteModels = false;
env.localModelPath = process.cwd() + "/models/";

const tokenizer = await AutoTokenizer.from_pretrained("lantern-sorter");
const text = process.argv[2];
const ids = tokenizer.encode(text);
console.log(ids.join(" "));
console.log(tokenizer.decode(ids));
JS

block tokens
on 'node tokens.mjs "Where is my order LB-20488? It has not arrived."'

put sort.mjs <<'JS'
import { pipeline, env } from "@huggingface/transformers";
import { readFileSync } from "node:fs";

env.allowRemoteModels = false;              // nothing is fetched from the Hub
env.localModelPath = process.cwd() + "/models/";

const classify = await pipeline("text-classification", "lantern-sorter", { dtype: "fp32" });
const cases = JSON.parse(readFileSync("cases/held-out.json", "utf8"));
let right = 0;
for (const c of cases) {
  const [top] = await classify(c.text);
  if (top.label === c.label) right++;
  console.log(`${c.id} ${top.label.padEnd(16)} ${top.score.toFixed(3)}  (${c.label})`);
}
console.log(`${right} of ${cases.length} held-out cases right`);
JS

block node
on 'time node sort.mjs'

put sort.html <<'HTML'
<!doctype html>
<meta charset="utf-8">
<title>lantern-sorter</title>
<textarea id="mail" rows="6" cols="60">Hi, I moved last week. Can you send order LB-20511 to my new address instead?</textarea>
<button id="go" disabled>Sort</button>
<p id="out">loading the model…</p>
<script type="module">
import { pipeline, env } from "./node_modules/@huggingface/transformers/dist/transformers.min.js";
env.allowLocalModels = true;                  // in a browser this starts off
env.allowRemoteModels = false;                // nothing is fetched from the Hub
env.localModelPath = "./models/";             // served from this page's own address
env.backends.onnx.wasm.wasmPaths = "/node_modules/onnxruntime-web/dist/";

const classify = await pipeline("text-classification", "lantern-sorter", { dtype: "fp32" });
const out = document.getElementById("out"), go = document.getElementById("go");
go.disabled = false;
out.textContent = "ready";
go.onclick = async () => {
  const [top] = await classify(document.getElementById("mail").value);
  out.textContent = `${top.label} ${top.score.toFixed(3)}`;
};
</script>
HTML

# ana serves ~/desk on her own machine, the way any static page is served.
lab exec ana "setsid sh -c 'echo \$\$ > /tmp/desk-http.pid; exec python -m http.server 8600 --bind 127.0.0.1' >/dev/null 2>&1 < /dev/null &"
sleep 1

block browser
on 'browse http://127.0.0.1:8600/sort.html'

block no-dtype
on 'sed "s/, { dtype: \"fp32\" }//" sort.html > sort-q8.html && grep -c dtype sort-q8.html'
on 'browse http://127.0.0.1:8600/sort-q8.html --wait 15'

kill "$(cat /tmp/desk-http.pid)" && rm -f /tmp/desk-http.pid
