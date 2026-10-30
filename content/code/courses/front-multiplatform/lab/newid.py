#!/usr/bin/env python3
"""newid.py PREFIX [N]: N fresh ids like se-xxxxxxxx, checked against the whole repository."""
import secrets, subprocess, sys
A = "0123456789abcdefghjkmnpqrstvwxyz"  # Crockford, lower case: no i l o u
prefix, n = sys.argv[1], int(sys.argv[2]) if len(sys.argv) > 2 else 1
out = []
while len(out) < n:
    i = prefix + "-" + "".join(secrets.choice(A) for _ in range(8))
    r = subprocess.run(["git", "-C", "/home/user/schooling", "grep", "-q", i], capture_output=True)
    hit = subprocess.run(["grep", "-rqF", i, "/home/user/schooling/content", "/home/user/schooling/docs"], capture_output=True)
    if r.returncode != 0 and hit.returncode != 0 and i not in out:
        out.append(i)
print("\n".join(out))
