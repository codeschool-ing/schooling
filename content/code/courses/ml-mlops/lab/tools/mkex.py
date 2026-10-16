"""mkex.py SPEC.py: build schooling-example fences in en and pt from a program and notes.

SPEC defines FILE (path of program), LANGUAGE, NAME (file shown), OUTPUT (optional),
and PARTS: list of (first line prefix, note_en, note_pt). Prints to SPEC.en / SPEC.pt.
"""
import json, os, sys, runpy
sys.argv[1] = os.path.abspath(sys.argv[1])
spec = runpy.run_path(sys.argv[1])
src = open(spec["FILE"]).read()
lines = src.splitlines(keepends=True)
starts = []
for prefix, en, pt in spec["PARTS"]:
    idx = [i for i, l in enumerate(lines) if l.startswith(prefix) and (not starts or i > starts[-1])]
    if not idx:
        sys.exit(f"no line starts with {prefix!r}")
    starts.append(idx[0])
assert starts[0] == 0, "first part must start at line 0"
for lang, k in (("en", 1), ("pt", 2)):
    parts = []
    for j, (p, *notes) in enumerate(spec["PARTS"]):
        code = "".join(lines[starts[j]: starts[j + 1] if j + 1 < len(starts) else len(lines)])
        part = {"code": code}
        if notes[k - 1]:
            part["note"] = notes[k - 1]
        parts.append(part)
    ex = {"language": spec["LANGUAGE"], "file": spec["NAME"], "parts": parts}
    if spec.get("OUTPUT"):
        ex["output"] = spec["OUTPUT"]
    assert "".join(p["code"] for p in parts) == src
    open(sys.argv[1][:-3] + "." + lang, "w").write("```schooling-example\n" + json.dumps(ex, ensure_ascii=False, indent=2) + "\n```\n")
print("ok")
