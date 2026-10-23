#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of svelte, as a script that
# produces them. Its output is pasted into the lesson by lab/fill.py.
#
#   sudo bash captures.sh > /tmp/l6.txt
#   python3 ../../lab/fill.py snippets.md /tmp/l6.txt --blocks snippet
#   for f in children passing-snippets what-a-snippet-is; do
#     python3 ../../lab/fill.py $f.md /tmp/l6.txt; done
#
# It starts from the project as lesson 5 committed it. STAGED: the files ana
# writes, taken out of the lesson's .md by lab/shown.py.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/lib.sh

from_lesson 5
bg_stop dev
bg dev '~/planner' 'npm run dev'
wait_port 5173

shown children.md src/lib/Panel.svelte '~/planner/src/lib/Panel.svelte'
shown children.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block panel
session '~/planner' "look http://localhost:5173/ --click 'Spanish'"

# The snippet of "Snippets", put in place of the page's list exactly as shown.
python3 - /home/ana/planner/src/routes/+page.svelte snippets.md <<'PY'
import re, sys
page, md = sys.argv[1:]
frag = re.search(r"^```html\n(.*?)^```$", open(md).read(), re.S | re.M).group(1)
t = open(page).read()
old = re.search(r"\t\t<ul>\n\t\t\t\{#each ofCourse as session\}.*?\t\t</ul>\n", t, re.S).group(0)
open(page, "w").write(t.replace(old, "".join("\t\t" + l + "\n" if l else "\n" for l in frag.rstrip("\n").split("\n"))))
PY
sleep 1
block snippet
session '~/planner' "look http://localhost:5173/ --click 'Spanish'"

shown passing-snippets.md src/lib/List.svelte '~/planner/src/lib/List.svelte'
shown passing-snippets.md src/routes/+page.svelte '~/planner/src/routes/+page.svelte'
sleep 1
block list
session '~/planner' 'look http://localhost:5173/'
block list-empty
session '~/planner' "look http://localhost:5173/ --click 'Next week'"

block compile-list
session '~/planner' 'node compile.mjs src/lib/List.svelte'
done_lesson 6 "Panel and List, with snippets"
