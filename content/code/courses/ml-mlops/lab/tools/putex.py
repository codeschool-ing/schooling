"""putex.py NAME MD [MD...]: put ex/NAME.en or .pt into MD at @@ex:NAME@@, or over the example naming the same file."""
import json, re, sys, os
D = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "examples")
name = sys.argv[1]
for md in sys.argv[2:]:
    lang = "pt" if md.endswith(".pt.md") else "en"
    new = open(f"{D}/{name}.{lang}").read().rstrip("\n")
    file = json.loads(new.split("\n", 1)[1].rsplit("```", 1)[0])["file"]
    src = open(md).read()
    if f"@@ex:{name}@@" in src:
        out = src.replace(f"@@ex:{name}@@", new)
    else:
        pat = re.compile(r"```schooling-example\n(\{.*?\})\n```", re.S)
        def sw(m):
            return new if json.loads(m.group(1)).get("file") == file else m.group(0)
        out = pat.sub(sw, src)
    if out == src:
        print(f"{md}: unchanged")
        continue
    open(md, "w").write(out)
print("ok")
