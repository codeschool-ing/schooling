"""putprog.py MD [MD...]: replace each @@prog:FILE@@ line with lab/programs/FILE as a fence.

The language comes from the extension. Run it before withfences.py makes a
translation, so the two languages carry the same bytes.
"""
import os, re, sys
HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LANG = {".py": "python", ".yaml": "yaml", ".yml": "yaml", ".sh": "sh", ".sql": "sql", ".toml": "toml",
        ".json": "json", ".ini": "ini", ".cfg": "ini", ".txt": ""}
for md in sys.argv[1:]:
    s = open(md).read()
    def sub(m):
        name = m.group(1)
        body = open(os.path.join(HERE, "programs", name)).read()
        return "```%s\n%s```" % (LANG[os.path.splitext(name)[1]], body)
    new = re.sub(r"^@@prog:(\S+)@@$", sub, s, flags=re.M)
    if new != s:
        open(md, "w").write(new)
        print("putprog:", md)
