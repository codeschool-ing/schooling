#!/usr/bin/env bash
# The lab of prompt-reliability, as the lessons build it.
#
#   bash lab.sh files N      write ~/triage as a student has it after lesson N
#   bash lab.sh check        Ollama answers, and the model the lessons use is here
#   bash lab.sh reset        the old stand-in lab, for the lessons not yet moved
#
# THE STUDENT NEVER RECEIVES THIS FILE, and nothing in it is a file of its own.
# Every program, prompt and test set in ~/triage is a fence in a lesson,
# introduced by a sentence ending in "Save ... as `PATH`:" (or "Save this as
# `PATH`:"). `files N` walks lessons 1 to N in the order course.json lists them,
# and their sections in the order lesson.json lists them, and writes each such
# fence to ~/triage/PATH. A later fence for the same path replaces an earlier
# one, which is how a lesson changes a file. A schooling-example is written as
# its parts joined by newlines, which is what its copy button hands over.
#
# So the program a capture runs IS the program the lesson shows: there is no
# second copy to drift.
#
# The model is real: Ollama, with llama3.2:3b unless a lesson says otherwise.
# Every captures.sh names the model, its tag and the date in its header.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
LAB=${TRIAGE:-$HOME/triage}

files() {
  local upto=$1
  mkdir -p "$LAB"
  python3 - "$here" "$upto" "$LAB" <<'PY'
import json, os, re, sys
course, upto, lab = sys.argv[1], int(sys.argv[2]), sys.argv[3]
lessons = json.load(open(os.path.join(course, "course.json")))["lessons"][:upto]
fence = re.compile(r"^```([a-z-]*)\n(.*?)\n```$", re.S | re.M)
said = re.compile(r"\bSave\b[^`]*(?:`[^`]*`[^`]*)*?`([\w./-]+)`:\s*$", re.S)
written = {}
for lid in lessons:
    sections = json.load(open(os.path.join(course, "lessons", lid, "lesson.json")))["sections"]
    for s in sections:
        md = os.path.join(course, "lessons", lid, s["slug"] + ".md")
        if not os.path.exists(md):
            continue
        text = open(md, encoding="utf-8").read()
        for m in fence.finditer(text):
            before = text[:m.start()].rstrip("\n")
            para = before[before.rfind("\n\n") + 2:] if "\n\n" in before else before
            got = said.search(para)
            if not got:
                continue
            path, lang, body = got.group(1), m.group(1), m.group(2)
            if lang == "schooling-example":
                body = "\n".join(p["code"] for p in json.loads(body)["parts"])
            target = os.path.join(lab, path)
            os.makedirs(os.path.dirname(target) or lab, exist_ok=True)
            with open(target, "w", encoding="utf-8") as f:
                f.write(body + "\n")
            written[path] = "%s/%s" % (lid, s["slug"])
if not written:
    sys.exit("lab.sh: lessons 1 to %d save no file" % upto)
# The one file a lesson has the student MAKE rather than save: lesson 5,
# measuring-it.md, joins the two test sets with this command, and every
# lesson after it reads cases/all.jsonl.
if upto >= 5:
    with open(os.path.join(lab, "cases/all.jsonl"), "w", encoding="utf-8") as out:
        for part in ("cases/dev.jsonl", "cases/holdout.jsonl"):
            out.write(open(os.path.join(lab, part), encoding="utf-8").read())
    written["cases/all.jsonl"] = "cat cases/dev.jsonl cases/holdout.jsonl > cases/all.jsonl"
# And the one edit a lesson has the student make to pl.py rather than save it
# again: lesson 6, setting-the-cap.md, lets the contract allow a fourth
# field, with this sed, when the prompt starts asking for one.
if upto >= 6:
    p = os.path.join(lab, "pl.py")
    src = open(p, encoding="utf-8").read()
    old = 'and k != "summary"'
    if src.count(old) != 1:
        sys.exit("lab.sh: pl.py no longer has the line setting-the-cap.md edits")
    open(p, "w", encoding="utf-8").write(src.replace(old, 'and k not in ("summary", "confidence")'))
    written["pl.py"] += ", then the sed in setting-the-cap"
for path in sorted(written):
    print("%-28s from %s" % (path, written[path]), file=sys.stderr)
PY
}

check() {
  curl -fsS "${OLLAMA_HOST:-http://127.0.0.1:11434}/api/tags" >/dev/null ||
    { echo "lab.sh: Ollama does not answer; start it with: ollama serve" >&2; exit 1; }
  ollama list | grep -q '^llama3.2:3b ' ||
    { echo "lab.sh: llama3.2:3b is not pulled; run: ollama pull llama3.2:3b" >&2; exit 1; }
}

case "${1:-}" in
  files) files "${2:?files needs a lesson number}" ;;
  check) check ;;
  reset) bash "$here/standin-lab.sh" reset ;;
  *) echo "usage: bash lab.sh files N | check | reset" >&2; exit 2 ;;
esac
