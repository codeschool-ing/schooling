"""ids.py PREFIX [N]: print N new ids (default 1), each unique in the repository.

An id is written down, never worked out: eight characters of Crockford's
base32 without i, l, o or u, behind a two-letter prefix (se, vd, ex). This
prints candidates drawn at random and drops any that already appear anywhere
under content/ or in an id printed earlier by this run.
"""
import os, random, subprocess, sys

ALPHABET = "0123456789abcdefghjkmnpqrstvwxyz"
prefix = sys.argv[1]
n = int(sys.argv[2]) if len(sys.argv) > 2 else 1
root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", "..")
taken = set(subprocess.run(["grep", "-rhoE", r"\b[a-z]{2}-[0-9a-z]{8}\b", root],
                           capture_output=True, text=True).stdout.split())
seen_file = "/tmp/angular-ids-issued"
if os.path.exists(seen_file):
    taken |= set(open(seen_file).read().split())
out = []
while len(out) < n:
    c = f"{prefix}-" + "".join(random.choice(ALPHABET) for _ in range(8))
    if c not in taken:
        taken.add(c); out.append(c)
with open(seen_file, "a") as f:
    f.write("\n".join(out) + "\n")
print("\n".join(out))
