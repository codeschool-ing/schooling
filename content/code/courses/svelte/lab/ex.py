"""ex.py FILE...: write each annotated example of a draft as the JSON the format wants.

An author writes a schooling-example as a fence labelled "example", which
reads like the program it is:

    ```example
    file: app.js
    language: javascript
    --- The note beside the first part, in one line.
    const a = 1;
    --- The note beside the second.
    console.log(a);
    ```

"---" alone starts a part with no note. A translation writes only the notes,
one "---" line per part, in the same order, and pt.py puts the code back.
Run on a file, every "example" fence becomes a "schooling-example" fence.
"""
import json, re, sys

def fmt(e):
    head = {k: e[k] for k in ("language", "file") if k in e}
    s = "{" + ", ".join(f"{json.dumps(k)}: {json.dumps(v, ensure_ascii=False)}" for k, v in head.items())
    s += ', "parts": [\n' + ",\n".join(" " + json.dumps(p, ensure_ascii=False) for p in e["parts"]) + "\n]"
    if "output" in e:
        s += ', "output": ' + json.dumps(e["output"], ensure_ascii=False)
    return s + "}\n"

def parse(body):
    e, parts, cur = {}, [], None
    for line in body.split("\n"):
        if cur is None and re.match(r"^(file|language): ", line):
            k, v = line.split(": ", 1); e[k] = v; continue
        if line.startswith("---"):
            note = line[3:].strip()
            cur = {"code": [], "note": note}; parts.append(cur); continue
        if cur is not None:
            cur["code"].append(line)
        elif line.strip():
            raise SystemExit(f"ex.py: a line before the first '---' would be lost: {line!r}")
    out = []
    for p in parts:
        code = "\n".join(p["code"]).rstrip("\n")
        d = {"code": code}
        if p["note"]: d["note"] = p["note"]
        out.append(d)
    e["parts"] = out
    return e

def main(files):
  for f in files:
    t = open(f, encoding="utf-8").read()
    n = [0]
    def repl(m):
        n[0] += 1
        return "```schooling-example\n" + fmt(parse(m.group(1))) + "```"
    t = re.sub(r"^```example\n(.*?)^```$", repl, t, flags=re.S | re.M)
    open(f, "w", encoding="utf-8").write(t)
    if n[0]: print(f"{f}: {n[0]} example(s)")


if __name__ == "__main__":
    main(sys.argv[1:])
