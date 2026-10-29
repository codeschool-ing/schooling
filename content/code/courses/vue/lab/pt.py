"""pt.py MD PT: put the English fences into the translation, place by place.

A .pt.md translates the prose and never the program, so its fences are the
English ones. The translation is written with each fence where it goes; a
fence whose body is "@@" (or any fence that is not a figure or an example)
is replaced by the English fence at the same position. A schooling-example
keeps its translated notes and takes everything else from the English. A
schooling-figure is left alone: it is translated whole. A count that does not
match is an error, because a fence out of place moves every one after it.
"""
import json, re, sys
sys.path.insert(0, __import__("os").path.dirname(__file__))
from ex import fmt, parse

FENCE = re.compile(r"^```([a-z-]*)\n(.*?)^```$", re.S | re.M)
md, pt = sys.argv[1], sys.argv[2]
en = [(m.group(1), m.group(2)) for m in FENCE.finditer(open(md, encoding="utf-8").read())]
text = open(pt, encoding="utf-8").read()
ptf = list(FENCE.finditer(text))
if len(en) != len(ptf):
    sys.exit(f"{pt}: {len(ptf)} fences against {len(en)} in {md}")
i = -1
def repl(m):
    global i
    i += 1
    label, body = m.group(1), m.group(2)
    elabel, ebody = en[i]
    if label == "example":
        notes = [x.get("note") for x in parse("file: x\n" + body)["parts"]]
        body = json.dumps({"parts": [{"note": n} if n else {} for n in notes]}); label = "schooling-example"
    if label == "localised" and elabel == "localised":
        return m.group(0)
    if label == "schooling-figure":
        if elabel != label: sys.exit(f"{pt}: fence {i} is a figure and the English is {elabel}")
        return m.group(0)
    if label == "schooling-example":
        e = json.loads(ebody)
        notes = [x.get("note") for x in json.loads(body)["parts"]]
        if len(notes) != len(e["parts"]): sys.exit(f"{pt}: example {i} has {len(notes)} notes for {len(e['parts'])} parts")
        for part, n in zip(e["parts"], notes):
            if n: part["note"] = n
            else: part.pop("note", None)
        return "```schooling-example\n" + fmt(e) + "```"
    return f"```{elabel}\n{ebody}```"
out = FENCE.sub(repl, text)
open(pt, "w", encoding="utf-8").write(out)
print(f"{pt}: {len(en)} fences in place")
