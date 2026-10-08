#!/usr/bin/env bash
# The lab of ai-security: ~/guard, built from the lessons themselves.
#
#   bash lab.sh reset      rebuild ~/guard from nothing
#
# THE LESSONS ARE THE SOURCE. This script holds no program and no data of its
# own: it walks the lessons in course order, sections in lesson order, and
# does what a student does with what they print —
#
#   - a ```python fence whose first line is `# NAME.py: ...` is saved as
#     ~/guard/tools/NAME.py;
#   - a ```schooling-example whose "file" is tools/NAME.py is saved there, its
#     parts joined, which is what its copy button hands over;
#   - a ```sh fence whose first line starts `mkdir -p ~/guard` or
#     `cat > ~/guard/` is run, which is how the dispatcher in bin/guard and
#     every data file a lesson pastes come to exist.
#
# So the program a capture ran is the program the student typed, and the two
# cannot drift apart: change a fence and the next capture runs the change.
# Every other fence (apt-get, the Ollama installer, ~/.bashrc) is the
# student's machine rather than the lab, and is not run here.
#
# It needs Python 3.8 or later. The tools that ask a model (`guard ask` and
# the ones that import it) also need Ollama serving llama3.2:3b; nothing here
# starts it. Set GUARD_HOME to build under a HOME other than your own.
#
# THE STORY. Tarefa is a Brazilian marketplace where clients hire
# freelancers, and it has an assistant built on a third-party model. Tarefa
# is invented, and so is every person, company, CPF, card and key in the
# data; what each file was written for is said in the lesson that pastes it.
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export HOME=${GUARD_HOME:-$HOME}

case ${1:-} in
  reset) ;;
  *) echo "usage: bash lab.sh reset" >&2; exit 2 ;;
esac

rm -rf "$HOME/guard"
python3 - "$here" <<'PY'
import json, os, re, subprocess, sys

course = sys.argv[1]
guard = os.path.expanduser("~/guard")
fence = re.compile(r"^```([\w-]*)\n(.*?)^```$", re.S | re.M)
saved = set()

def save(name, text):
    if name in saved:
        sys.exit("lab.sh: two lessons print tools/%s" % name)
    saved.add(name)
    os.makedirs(os.path.join(guard, "tools"), exist_ok=True)
    with open(os.path.join(guard, "tools", name), "w", encoding="utf-8") as f:
        f.write(text)

for lesson in json.load(open(os.path.join(course, "course.json")))["lessons"]:
    base = os.path.join(course, "lessons", lesson)
    for s in json.load(open(os.path.join(base, "lesson.json")))["sections"]:
        md = os.path.join(base, s["slug"] + ".md")
        if not os.path.exists(md):
            continue
        for lang, body in fence.findall(open(md, encoding="utf-8").read()):
            first = body.split("\n", 1)[0]
            if lang == "python":
                m = re.match(r"# ([\w-]+\.py):", first)
                if m:
                    save(m.group(1), body)
            elif lang == "schooling-example":
                ex = json.loads(body)
                if ex.get("file", "").startswith("tools/"):
                    save(ex["file"][6:], "".join(p["code"] for p in ex["parts"]))
            elif lang == "sh" and (first.startswith("mkdir -p ~/guard")
                                   or first.startswith("cat > ~/guard/")):
                subprocess.run(["bash", "-euo", "pipefail", "-c", body], check=True)
PY
echo "lab ready in $HOME/guard"
