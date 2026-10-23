"""The files a lesson shows whole, read out of its Markdown.

    shown.py MD NAME      print the fence under the paragraph that ends in
                          "as `NAME`:" (a schooling-example: its code parts)
    shown.py --check LAB  every such fence in every lesson, against the file of
                          the same path in lab/stages/NN, where NN is the
                          lesson's position in course.json; prints each
                          difference and exits 1 if there is one

A label naming a path outside the project (`~/...`) is checked only when
lab/stages/NN holds a file of that name under _home/.
"""
import difflib
import json
import re
import sys
from pathlib import Path

LABEL = re.compile(r"\bas `([~\w./-]+)`:$")


def blocks(md):
    lines = md.read_text().split("\n")
    i, prev, ended = 0, "", True
    while i < len(lines):
        m = re.match(r"^(`{3,})(\S*)\s*$", lines[i])
        if not m:
            if not lines[i].strip():
                ended = True
            else:
                prev = lines[i].strip() if ended else prev + " " + lines[i].strip()
                ended = False
            i += 1
            continue
        fence, lang = m.groups()
        j = i + 1
        while lines[j].rstrip() != fence:
            j += 1
        body = "\n".join(lines[i + 1:j])
        label = LABEL.search(prev)
        if label:
            if lang == "schooling-example":
                body = "\n".join(p["code"] for p in json.loads(body)["parts"])
            yield label.group(1), body + ("" if body.endswith("\n") else "\n")
        prev, ended, i = "", True, j + 1


def main():
    if sys.argv[1] != "--check":
        for name, body in blocks(Path(sys.argv[1])):
            if name == sys.argv[2]:
                sys.stdout.write(body)
                return 0
        print(f"{sys.argv[1]} shows no {sys.argv[2]}", file=sys.stderr)
        return 1
    lab = Path(sys.argv[2])
    course = json.loads((lab / "course.json").read_text())
    bad = seen = 0
    for n, lesson in enumerate(course["lessons"], 1):
        stage = lab / "lab" / "stages" / f"{n:02d}"
        for md in sorted((lab / "lessons" / lesson).glob("*.md")):
            if md.name.endswith(".pt.md"):
                continue
            for name, body in blocks(md):
                rel = "_home/" + name[2:] if name.startswith("~/") else name
                want = stage / rel
                if not want.exists():
                    if name.startswith("~/"):
                        continue
                    print(f"{md.relative_to(lab)}: shows {name}, and stage {n:02d} has no such file")
                    bad += 1
                    continue
                seen += 1
                if want.read_text() != body:
                    bad += 1
                    print(f"{md.relative_to(lab)}: {name} differs from {want.relative_to(lab)}")
                    sys.stdout.writelines(difflib.unified_diff(
                        want.read_text().splitlines(True), body.splitlines(True), "stage", "lesson"))
    print(f"{seen} file(s) shown, {bad} difference(s)")
    return 1 if bad else 0


sys.exit(main())
