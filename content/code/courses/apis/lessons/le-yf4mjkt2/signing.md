```python
# shelf/hs256.py
"""Recompute a token's HS256 signature with nothing but hmac, and compare."""
import base64
import hashlib
import hmac
import sys

header, payload, signature = sys.argv[1].split(".")
with open("jwt.key", "rb") as f:
    key = f.read()
mac = hmac.new(key, f"{header}.{payload}".encode(), hashlib.sha256).digest()
mine = base64.urlsafe_b64encode(mac).rstrip(b"=").decode()
print("in the token:", signature)
print("recomputed:  ", mine)
print("they match" if hmac.compare_digest(mine, signature) else "they differ")
```
