"""withfences.py EN.md PT_TEMPLATE OUT: fill @@FENCE@@ markers in the template with EN's code fences, in order."""
import re, sys
en = open(sys.argv[1]).read()
fences = [m.group(0) for m in re.finditer(r"^```(python|sh|yaml|json|sql|ini|toml|dockerfile|bash)\n.*?^```$", en, re.S | re.M)]
t = open(sys.argv[2]).read()
n = t.count("@@FENCE@@")
if n != len(fences):
    sys.exit(f"{n} markers, {len(fences)} fences")
for f in fences:
    t = t.replace("@@FENCE@@", f, 1)
open(sys.argv[3], "w").write(t)
print("ok")
