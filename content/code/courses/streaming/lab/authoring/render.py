#!/usr/bin/env python3
"""render.py FILE...: turn a draft schooling-example into its JSON, in place.

Draft (EN):                          Draft (PT), code taken from the EN file at the same position:
```schooling-example                 ```schooling-example
@file x.py                           @same
@lang python                         --- nota
--- note (several lines allowed)     ---
code                                 --- nota
--- (empty note)                     ```
code
@output
text
```
"""
import json, re, sys
pat = re.compile(r"^```schooling-example\n(.*?)^```$", re.S | re.M)
def examples(text):
    return [json.loads(b) for b in pat.findall(text) if b.lstrip().startswith("{")]
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    src = None
    if path.endswith(".pt.md"):
        try: src = examples(open(path[:-6] + ".md", encoding="utf-8").read())
        except FileNotFoundError: src = []
    idx = [0]
    def sub(m):
        body = m.group(1)
        k = idx[0]; idx[0] += 1
        if body.lstrip().startswith("{"): return m.group(0)
        lines = body.split("\n")
        ex = {}; parts = []; mode = None; note = []; code = []; output = []
        def flush():
            if mode == "part":
                p = {"code": "\n".join(code)}
                n = " ".join(x.strip() for x in note).strip()
                if n: p["note"] = n
                parts.append(p)
        for ln in lines:
            if ln.startswith("@file "): ex["file"] = ln[6:].strip(); continue
            if ln.startswith("@lang "): ex["language"] = ln[6:].strip(); continue
            if ln.strip() == "@same":
                base = src[k]; ex = {kk: base[kk] for kk in ("language", "file") if kk in base}; ex["@same"] = base; continue
            if ln.startswith("@output"):
                flush(); mode = "output"; continue
            if ln.startswith("---"):
                flush(); mode = "part"; note = [ln[3:]]; code = []; in_note = True; continue
            if mode == "part":
                if ex.get("@same") is not None: note.append(ln); continue
                if not code and ln.strip() and not ln.startswith(" ") and not code and note and _is_note(ln):
                    note.append(ln); continue
                code.append(ln)
            elif mode == "output":
                output.append(ln)
        flush()
        if parts: parts[-1]["code"] = parts[-1]["code"].rstrip("\n")
        base = ex.pop("@same", None)
        if base is not None:
            if len(parts) != len(base["parts"]): sys.exit(f"{path}: {len(parts)} notes for {len(base['parts'])} parts")
            parts = [dict(({"code": bp["code"]}), **({"note": p["note"]} if p.get("note") else {})) for p, bp in zip(parts, base["parts"])]
            out = dict(ex); out["parts"] = parts
            if "output" in base: out["output"] = base["output"]
        else:
            out = dict(ex); out["parts"] = parts
            if output: out["output"] = "\n".join(output).rstrip("\n")
        return "```schooling-example\n" + json.dumps(out, ensure_ascii=False, indent=2) + "\n```"
    def _is_note(ln): return False
    globals()["_is_note"] = _is_note
    new = pat.sub(sub, text)
    if new != text:
        open(path, "w", encoding="utf-8").write(new); print("rendered", path)
