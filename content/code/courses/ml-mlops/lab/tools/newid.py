import secrets, subprocess, sys
A = "0123456789abcdefghjkmnpqrstvwxyz"
prefix, n = sys.argv[1], int(sys.argv[2])
out = []
while len(out) < n:
    i = prefix + "-" + "".join(secrets.choice(A) for _ in range(8))
    r = subprocess.run(["grep", "-rqF", i, "/home/user/schooling/content", "/home/user/schooling/docs"], capture_output=True)
    if r.returncode == 1 and i not in out:
        out.append(i)
print(" ".join(out))
